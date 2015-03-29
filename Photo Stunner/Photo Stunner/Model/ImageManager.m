//
//  ImageManager.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "ImageManager.h"
#import <AVFoundation/AVFoundation.h>

#define dispatch_async_main_safe(block)\
    do {\
        if ([NSThread isMainThread]) block();\
        else dispatch_async(dispatch_get_main_queue(), block);\
    } while (0)

@interface ImageManager ()

@property (nonatomic) NSMutableDictionary *filePaths;
@property (nonatomic) NSMutableArray *internalSortedTimes;
@property (nonatomic) NSCache *cache;
+ (dispatch_queue_t) fileIOQueue;

@end

@implementation ImageManager

static NSString * const FilePathsOriginalImagePathKey = @"filepaths original image key";
static NSString * const FilePathsThumbnailImagePathKey = @"filepaths thumbnail image key";

NSString * const ImageManagerSortedTimesChangedNotification = @"image manager sortedtimes changed notification";
NSString * const ImageManagerSortedTimesRemovedIndexKey = @"image manager sortedtimes removed index key";
NSString * const ImageManagerSortedTimesAddedIndexKey = @"image manager sortedtimes added index key";
#define ImageManagerDirectory [NSTemporaryDirectory() stringByAppendingPathComponent:@"ImageManager"]
#define DefaultThumbnailSize CGSizeMake (25.0f, 25.0f)

#pragma mark life cycle

+ (void) initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [ImageManager clearDirectory];
    });
}

- (instancetype) init {
    self = [super init];
    if (self) {
        self.filePaths = [NSMutableDictionary new];
        self.internalSortedTimes = [NSMutableArray new];
        self.cache = [NSCache new];
        self.thumbnailImageMaxSize = DefaultThumbnailSize;
    }
    return self;
}

#pragma mark adding

- (void)addImage:(UIImage *)image forTime:(CMTime)time {
    [self addImage:image forTime:time completion:nil];
}

- (void)addImage:(UIImage *)image forTime:(CMTime)time completion:(void (^)(CMTime, UIImage *))completion {
    __weak typeof (self) weakSelf = self;
    
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];

    if (self.filePaths[wrappedTime]) {
        NSString *timeStr = CFBridgingRelease(CMTimeCopyDescription(NULL, time));
        NSString *reason = [NSString stringWithFormat:@"Cannot add image for time %@ because an image for that time already exists.", timeStr];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    [self createThumbnailImageForImage:image completion:^(UIImage *image, UIImage *thumbnailImage) {
        assert (image);
        assert (thumbnailImage);
        
        [weakSelf addImage:image completion:^(UIImage *image, NSString *filePath) {
            assert (image);
            assert (filePath);
            
            [weakSelf addImage:thumbnailImage completion:^(UIImage *thumbnailImage, NSString *thumbnailImageFilePath) {
                assert (thumbnailImage);
                assert (thumbnailImageFilePath);
                
                weakSelf.filePaths[wrappedTime] = @{
                    FilePathsOriginalImagePathKey : filePath,
                    FilePathsThumbnailImagePathKey : thumbnailImageFilePath
                };
                
                [weakSelf.internalSortedTimes addObject:wrappedTime];
                [weakSelf.internalSortedTimes sortUsingComparator:[ImageManager comparatorForSorting]];
                NSUInteger addedIndex = [weakSelf.internalSortedTimes indexOfObject:wrappedTime];
                
                assert (addedIndex != NSNotFound);
                
                if (completion) {
                    dispatch_async_main_safe(^{completion(time,image);});
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ImageManagerSortedTimesChangedNotification
                                                                        object:self
                                                                  userInfo:@{ImageManagerSortedTimesAddedIndexKey : @(addedIndex)}];
                
            }];
        }];
    }];
}

- (void)addImage:(UIImage *)image completion:(void(^)(UIImage *image, NSString *filePath))completion {
    
    dispatch_async([ImageManager fileIOQueue], ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *filePath = [self freshFilePath];
        
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:NO];
        assert ([fileManager fileExistsAtPath:filePath]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.cache setObject:image forKey:filePath];
            if (completion) {
                dispatch_async_main_safe(^{completion (image, filePath);});
            }
        });
    });
}

#pragma mark retrieving

- (void)retrieveThumbnailImageForTime:(CMTime)time completion:(void (^)(CMTime, UIImage *))completion {
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];

    if (!self.filePaths[wrappedTime]) {
        NSString *timeStr = CFBridgingRelease(CMTimeCopyDescription(NULL, time));
        NSString *reason = [NSString stringWithFormat:@"Cannot retrieve thumbnail image for time %@ because it has not been added.", timeStr];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *thumbnailFilePath = self.filePaths[wrappedTime][FilePathsThumbnailImagePathKey];
    assert (thumbnailFilePath);
    
    [self retrieveImageAtPath:thumbnailFilePath completion:^(NSString *thumbnailFilePath, UIImage *thumbnailImage) {
        if (completion) {
            dispatch_async_main_safe(^{completion (time, thumbnailImage);});
        }
    }];
}

- (void)retrieveImageForTime:(CMTime)time completion:(void (^)(CMTime, UIImage *))completion {
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];

    if (!self.filePaths[wrappedTime]) {
        NSString *timeStr = CFBridgingRelease(CMTimeCopyDescription(NULL, time));
        NSString *reason = [NSString stringWithFormat:@"Cannot retrieve image for time %@ because it has not been added.", timeStr];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *filePath = self.filePaths[wrappedTime][FilePathsOriginalImagePathKey];
    assert (filePath);
    
    [self retrieveImageAtPath:filePath completion:^(NSString *filePath, UIImage *result) {
        if (completion) {
            dispatch_async_main_safe(^{completion (time, result);});
        }
    }];
}

- (void)retrieveImageAtPath:(NSString *)filePath completion:(void(^)(NSString *filePath, UIImage *image))completion {
    assert (filePath);
    
    UIImage *cachedImage = [self.cache objectForKey:filePath];
    if (cachedImage) {
        if (completion) {
            dispatch_async_main_safe(^{completion (filePath, cachedImage);});
        }
        return;
    }
        
    dispatch_async([ImageManager fileIOQueue], ^{
        UIImage *diskImage = [UIImage imageWithContentsOfFile:filePath];
        assert (diskImage);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                dispatch_async_main_safe(^{completion (filePath, diskImage);});
            }
        });
    });
}


#pragma mark removal

- (void)removeAllImages {
    [self removeAllImagesWithCompletionBlock:nil];
}

- (void)removeAllImagesWithCompletionBlock:(void (^)(void))completion {
    NSArray *sortedTimesCopy = [self.internalSortedTimes copy];
    NSUInteger totalImages = [sortedTimesCopy count];
    __block NSUInteger imagesRemoved = 0;

    if (![sortedTimesCopy count]) {
        if (completion) {
            dispatch_async_main_safe (completion);
        }
    }
    
    for (NSValue *obj in sortedTimesCopy) {
        CMTime time = [obj CMTimeValue];
        [self removeImageForTime:time completion:^(CMTime removedTime) {
            if (++imagesRemoved == totalImages) {
                if (completion) {
                    dispatch_async_main_safe (completion);
                }
            }
        }];
    };
}

- (void)removeImageForTime:(CMTime)time {
    [self removeImageForTime:time completion:nil];
}

- (void)removeImageForTime:(CMTime)time completion:(void (^)(CMTime))completion {
    
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    
    if (!self.filePaths[wrappedTime]) {
        NSString *timeStr = CFBridgingRelease(CMTimeCopyDescription(NULL, time));
        NSString *reason = [NSString stringWithFormat:@"Cannot remove image for time %@ because it has not been added.", timeStr];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *filePath = self.filePaths[wrappedTime][FilePathsOriginalImagePathKey];
    NSString *thumbnailFilePath = self.filePaths[wrappedTime][FilePathsThumbnailImagePathKey];
    assert (filePath);
    assert (thumbnailFilePath);
    
    __weak typeof(self) weakSelf = self;
    
    [self removeImageAtPath:filePath completion:^(NSString *filePath) {
        [weakSelf removeImageAtPath:thumbnailFilePath completion:^(NSString *filePath) {
            NSUInteger removedIndex = [weakSelf.internalSortedTimes indexOfObject:wrappedTime];
            
            [weakSelf.filePaths removeObjectForKey:wrappedTime];
            [weakSelf.internalSortedTimes removeObject:wrappedTime];
            
            assert(removedIndex != NSNotFound);
            
            if (completion) {
                dispatch_async_main_safe(^{completion(time);});
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ImageManagerSortedTimesChangedNotification
                                                                object:self
                                                              userInfo:@{ImageManagerSortedTimesRemovedIndexKey : @(removedIndex)}];
        }];
    }];
}

- (void) removeImageAtPath:(NSString *)filePath completion:(void(^)(NSString *filePath))completion {

    dispatch_async([ImageManager fileIOQueue], ^{
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        assert (filePath);
        assert ([fileManager fileExistsAtPath:filePath]);
        
        [fileManager removeItemAtPath:filePath error:&error];
        
        assert (!error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                dispatch_async_main_safe(^{completion (filePath);});
            }
        });
    });
}

#pragma mark miscellaneous

+ (NSComparisonResult (^) (id obj1, id obj2)) comparatorForSorting {
    static NSComparisonResult (^comparator)(id obj1, id obj2) = ^NSComparisonResult(id obj1, id obj2) {
        CMTime time1 = [obj1 CMTimeValue];
        CMTime time2 = [obj2 CMTimeValue];
        
        int32_t compare = CMTimeCompare(time1, time2);
        
        return
        compare < 0 ?   NSOrderedAscending  :
        compare > 0 ?   NSOrderedDescending :
        NSOrderedSame;
    };
    return comparator;
}

- (NSString *) freshFilePath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath;
    
    do {
        uint32_t random = arc4random();
        NSString *fileName = [NSString stringWithFormat:@"%u.jpg", random];
        filePath = [ImageManagerDirectory stringByAppendingPathComponent:fileName];
    } while ([fileManager fileExistsAtPath:filePath]);
    
    return filePath;
}

- (CGSize) sizeForImage:(UIImage *)image givenMaximumSize:(CGSize)size {
    CGSize imageSize = [image size];
    CGFloat aspectRatio = imageSize.width/imageSize.height;
    CGSize result = size;
    
    if (aspectRatio > 1) {
        result.height = size.width / aspectRatio;
    } else {
        result.width = size.height * aspectRatio;
    }
    
    return result;
}

- (void)createThumbnailImageForImage:(UIImage *)image completion:(void(^)(UIImage *image, UIImage *thumbnailImage)) completion {
    assert (image);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        CGSize size = [self sizeForImage:image givenMaximumSize:[self thumbnailImageMaxSize]];
        
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        assert (thumbnailImage);
        
        if (completion) {
            dispatch_async_main_safe(^{completion (image, thumbnailImage);});
        }
    });
}

-(NSArray *)sortedTimes {
    return [self internalSortedTimes];
}

+ (void)clearDirectory {
    dispatch_async([ImageManager fileIOQueue], ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        
        NSError *error;
        if ([manager fileExistsAtPath:ImageManagerDirectory]) {
            [manager removeItemAtPath:ImageManagerDirectory error:&error];
            assert (!error);
        }
        [manager createDirectoryAtPath:ImageManagerDirectory withIntermediateDirectories:NO attributes:nil error:&error];
        assert (!error);
    });
}

+ (dispatch_queue_t)fileIOQueue {
    static dispatch_queue_t fileIOQueue;
    if (!fileIOQueue) {
        fileIOQueue = dispatch_queue_create("ImageManager.fileIOQueue", DISPATCH_QUEUE_SERIAL);
    }
    return fileIOQueue;
}

@end
