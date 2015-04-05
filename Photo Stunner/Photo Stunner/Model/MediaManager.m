//
//  ImageManager.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "MediaManager.h"
#import <AVFoundation/AVFoundation.h>
#import "Photo_Stunner-Swift.h"

#define dispatch_async_main_safe(block)\
    do {\
        if ([NSThread isMainThread]) block();\
        else dispatch_async(dispatch_get_main_queue(), block);\
    } while (0)

NSString * const MediaManagerContentChangedNotification = @"media manager content changed notification";
NSString * const MediaManagerContentChangeTypeKey = @"mediamanager content change type key";

NSString * const MediaManagerContentTypeKey = @"mediamanager content type key";
NSString * const MediaManagerContentKey = @"mediamanager content key";

#define ImageManagerDirectory [NSTemporaryDirectory() stringByAppendingPathComponent:@"ImageManager"]
#define DefaultThumbnailSize CGSizeMake (100.0f, 100.0f)

@interface MediaManager ()

@property (nonatomic, readwrite) CGSize thumbnailImageMaxSize;
@property (nonatomic) NSCache *cache;

@end

@interface MediaManager ()

@property (nonatomic) NSMutableDictionary *imageFilePaths;

@end


@interface MediaManager ()

@property (nonatomic) NSMutableDictionary *videoFilePaths;

@end

@implementation MediaManager

#define ImageManagerDirectory [NSTemporaryDirectory() stringByAppendingPathComponent:@"ImageManager"]
#define DefaultThumbnailSize CGSizeMake (100.0f, 100.0f)

#pragma mark life cycle

+ (void) initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[self class] clearDirectory];
    });
}

- (instancetype) init {
    if (arc4random_uniform(10) < 3) {
        return [StunningImageManager new];
    }
    
    self = [super init];
    if (self) {
        self.cache = [NSCache new];
        self.imageFilePaths = [NSMutableDictionary new];
        self.videoFilePaths = [NSMutableDictionary new];
        self.thumbnailImageMaxSize = DefaultThumbnailSize;
    }
    return self;
}

#pragma mark miscellaneous

+ (void)clearDirectory {
    dispatch_async([[self class] fileIOQueue], ^{
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

+ (NSString *) freshFilePathWithExtension:(NSString *)extension {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath;
    
    do {
        uint32_t random = arc4random();
        NSString *fileName = [NSString stringWithFormat:@"%u.%@", random, extension];
        filePath = [ImageManagerDirectory stringByAppendingPathComponent:fileName];
    } while ([fileManager fileExistsAtPath:filePath]);
    
    return filePath;
}

+ (CGSize) sizeForImage:(UIImage *)image givenMaximumSize:(CGSize)size {
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
        CGSize size = [[self class] sizeForImage:image givenMaximumSize:[self thumbnailImageMaxSize]];
        
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

+ (dispatch_queue_t)fileIOQueue {
    static dispatch_queue_t fileIOQueue;
    if (!fileIOQueue) {
        fileIOQueue = dispatch_queue_create("ImageManager.fileIOQueue", DISPATCH_QUEUE_SERIAL);
    }
    return fileIOQueue;
}

@end

@implementation MediaManager (Image)

NSString * const MediaManagerContentTypeImage = @"mediamanager content type image";
static NSString * const FilePathsImagePathKey = @"filepaths image path key";
static NSString * const FilePathsThumbnailImagePathKey = @"filepaths thumbnail image path key";

#pragma mark adding

- (NSArray *)allImageKeys {
    return [self.imageFilePaths allKeys];
}

- (void)addImage:(UIImage *)image forKey:(id)key {
    [self addImage:image forKey:key completion:nil];
}

- (void)addImage:(UIImage *)image forKey:(id)key completion:(void (^)(id, UIImage *))completion {
    __weak typeof (self) weakSelf = self;
    
    if (self.imageFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot add image for key %@ because an image for that key already exists.", key];
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
                
                weakSelf.imageFilePaths[key] = @{
                    FilePathsImagePathKey : filePath,
                    FilePathsThumbnailImagePathKey : thumbnailImageFilePath
                };
                
                if (completion) {
                    dispatch_async_main_safe(^{completion(key,image);});
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:MediaManagerContentChangedNotification
                                                                        object:self
                                                                  userInfo:@{MediaManagerContentChangeTypeKey : @(MediaManagerContentChangeAdd),
                                                                             MediaManagerContentTypeKey : MediaManagerContentTypeImage,
                                                                             MediaManagerContentKey : key}];
                
            }];
        }];
    }];
}

- (void)addImage:(UIImage *)image completion:(void(^)(UIImage *image, NSString *filePath))completion {
    
    dispatch_async([[self class] fileIOQueue], ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *filePath = [[self class] freshFilePathWithExtension:@"jpg"];
        
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

- (void)retrieveThumbnailImageForKey:(id)key completion:(void (^)(id, UIImage *))completion {
    if (!self.imageFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot retrieve thumbnail image for key %@ because it has not been added.", key];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *thumbnailFilePath = self.imageFilePaths[key][FilePathsThumbnailImagePathKey];
    assert (thumbnailFilePath);
    
    [self retrieveImageAtPath:thumbnailFilePath completion:^(NSString *thumbnailFilePath, UIImage *thumbnailImage) {
        if (completion) {
            dispatch_async_main_safe(^{completion (key, thumbnailImage);});
        }
    }];
}

- (void)retrieveImageForKey:(id)key completion:(void (^)(id, UIImage *))completion {
    if (!self.imageFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot retrieve image for key %@ because it has not been added.", key];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *filePath = self.imageFilePaths[key][FilePathsImagePathKey];
    assert (filePath);
    
    [self retrieveImageAtPath:filePath completion:^(NSString *filePath, UIImage *result) {
        if (completion) {
            dispatch_async_main_safe(^{completion (key, result);});
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
        
    dispatch_async([[self class] fileIOQueue], ^{
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
    NSArray *sortedTimesCopy = [self.imageFilePaths allKeys];
    NSUInteger totalImages = [sortedTimesCopy count];
    __block NSUInteger imagesRemoved = 0;

    if (![sortedTimesCopy count]) {
        if (completion) {
            dispatch_async_main_safe (completion);
        }
    }
    
    for (id key in sortedTimesCopy) {
        [self removeImageForKey:key completion:^(id key) {
            if (++imagesRemoved == totalImages) {
                if (completion) {
                    dispatch_async_main_safe (completion);
                }
            }
        }];
    };
}

- (void)removeImageForKey:(id)key {
    [self removeImageForKey:key completion:nil];
}

- (void)removeImageForKey:(id)key completion:(void (^)(id))completion {
    if (!self.imageFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot remove image for key %@ because it has not been added.", key];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *filePath = self.imageFilePaths[key][FilePathsImagePathKey];
    NSString *thumbnailFilePath = self.imageFilePaths[key][FilePathsThumbnailImagePathKey];
    assert (filePath);
    assert (thumbnailFilePath);
    
    __weak typeof(self) weakSelf = self;
    
    [self removeImageAtPath:filePath completion:^(NSString *filePath) {
        [weakSelf removeImageAtPath:thumbnailFilePath completion:^(NSString *filePath) {
            
            assert (weakSelf.imageFilePaths[key]);
            [weakSelf.imageFilePaths removeObjectForKey:key];
            
            if (completion) {
                dispatch_async_main_safe(^{completion(key);});
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:MediaManagerContentChangedNotification
                                                                object:self
                                                              userInfo:@{MediaManagerContentChangeTypeKey : @(MediaManagerContentChangeRemove),
                                                                         MediaManagerContentTypeKey : MediaManagerContentTypeImage,
                                                                         MediaManagerContentKey : key}];
        }];
    }];
}

- (void) removeImageAtPath:(NSString *)filePath completion:(void(^)(NSString *filePath))completion {

    dispatch_async([[self class] fileIOQueue], ^{
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

#pragma mark saving

- (void)saveImageToSavedPhotosAlbumForKey:(id)key {
    [self saveImageToSavedPhotosAlbumForKey:key completion:nil];
}

- (void) saveImageToSavedPhotosAlbumForKey:(id)key completion:(void (^)(void))completion {
    [self retrieveImageForKey:key completion:^(id key, UIImage *image) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)(completion));
        });
    }];
}

- (void) image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    assert ([NSThread isMainThread]);

    void(^completion)(void) = (__bridge void (^)(void))(contextInfo);
    if (completion) {
        completion ();
    }
}

@end

@implementation MediaManager (Video)

NSString * const MediaManagerContentTypeVideo = @"mediamanager content type video";
static NSString * const FilePathsVideoPathKey = @"filepaths video path key";
static NSString * const FilePathsVideoThumbnailImagePathKey = @"filepaths video thumbnail image path key";

- (NSArray *)allVideoKeys {
    return [self.videoFilePaths allKeys];
}

- (void)addVideo:(AVAsset *)video forKey:(id)key {
    [self addVideo:video forKey:key completion:nil];
}

- (void)addVideo:(AVAsset *)video forKey:(id)key completion:(void (^)(id, AVAsset *))completion {
    __weak typeof (self) weakSelf = self;
    
    if (self.videoFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot add video for key %@ because a video for that key already exists.", key];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    [self createThumbnailImageForVideo:video completion:^(AVAsset *video, UIImage *thumbnailImage) {
        assert (thumbnailImage);
        
        [weakSelf addVideo:video completion:^(AVAsset *video, NSString *filePath) {
            assert (video);
            assert (filePath);
            
            [weakSelf addImage:thumbnailImage completion:^(UIImage *thumbnailImage, NSString *thumbnailImageFilePath) {
                assert (thumbnailImage);
                assert (thumbnailImageFilePath);
                
                weakSelf.videoFilePaths[key] = @{
                    FilePathsVideoPathKey : filePath,
                    FilePathsVideoThumbnailImagePathKey : thumbnailImageFilePath
                };
                
                if (completion) {
                    dispatch_async_main_safe(^{completion(key,video);});
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:MediaManagerContentChangedNotification
                                                                    object:self
                                                                  userInfo:@{MediaManagerContentChangeTypeKey : @(MediaManagerContentChangeAdd),
                                                                             MediaManagerContentTypeKey : MediaManagerContentTypeVideo,
                                                                             MediaManagerContentKey : key}];
                
            }];
        }];
    }];
}

- (void)addVideo:(AVAsset *)video completion:(void(^)(AVAsset *video, NSString *filePath))completion {
    dispatch_async([[self class] fileIOQueue], ^{
        
        NSString *filePath = [[self class] freshFilePathWithExtension:@"mov"];
        
        AVAssetExportSession *exportSession = [AVAssetExportSession
                                               exportSessionWithAsset:video
                                               presetName:AVAssetExportPresetPassthrough];
        
        exportSession.outputURL = [NSURL fileURLWithPath:filePath];
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            if (AVAssetExportSessionStatusCompleted == exportSession.status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.cache setObject:video forKey:filePath];
                    if (completion) {
                        dispatch_async_main_safe(^{completion (video, filePath);});
                    }
                });
            } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
                assert (NO);
            } else {
                assert (NO);
            }
        }];
    });
}


- (void)retrieveVideoForKey:(id)key completion:(void (^)(id, AVAsset *))completion {
    if (!self.videoFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot retrieve video for key %@ because it has not been added.", key];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *filePath = self.videoFilePaths[key][FilePathsVideoPathKey];
    assert (filePath);
    
    [self retrieveVideoAtPath:filePath completion:^(NSString *filePath, AVAsset *result) {
        if (completion) {
            dispatch_async_main_safe(^{completion (key, result);});
        }
    }];
}

- (void)retrieveVideoThumbnailImageForKey:(id)key completion:(void (^)(id, UIImage *))completion {
    if (!self.videoFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot retrieve video thumbnail image for key %@ because it has not been added.", key];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *thumbnailFilePath = self.videoFilePaths[key][FilePathsVideoThumbnailImagePathKey];
    assert (thumbnailFilePath);
    
    [self retrieveImageAtPath:thumbnailFilePath completion:^(NSString *thumbnailFilePath, UIImage *thumbnailImage) {
        if (completion) {
            dispatch_async_main_safe(^{completion (key, thumbnailImage);});
        }
    }];
}

- (void)retrieveVideoAtPath:(NSString *)filePath completion:(void(^)(NSString *filePath, AVAsset *video))completion {
    assert (filePath);
    
    AVAsset *cachedVideo = [self.cache objectForKey:filePath];
    if (cachedVideo) {
        if (completion) {
            dispatch_async_main_safe(^{completion (filePath, cachedVideo);});
        }
        return;
    }
    
    dispatch_async([[self class] fileIOQueue], ^{
        AVAsset *diskVideo = [AVAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
        assert (diskVideo);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                dispatch_async_main_safe(^{completion (filePath, diskVideo);});
            }
        });
    });
}

- (void)removeVideoForKey:(id)key {
    [self removeVideoForKey:key completion:nil];
}

- (void)removeVideoForKey:(id)key completion:(void (^)(id))completion {
    if (!self.videoFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot remove video for key %@ because it has not been added.", key];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *filePath = self.videoFilePaths[key][FilePathsVideoPathKey];
    NSString *thumbnailFilePath = self.videoFilePaths[key][FilePathsVideoThumbnailImagePathKey];
    assert (filePath);
    assert (thumbnailFilePath);
    
    __weak typeof(self) weakSelf = self;
    
    [self removeImageAtPath:filePath completion:^(NSString *filePath) {
        [weakSelf removeImageAtPath:thumbnailFilePath completion:^(NSString *filePath) {
            
            assert (weakSelf.videoFilePaths[key]);
            [weakSelf.videoFilePaths removeObjectForKey:key];
            
            if (completion) {
                dispatch_async_main_safe(^{completion(key);});
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:MediaManagerContentChangedNotification
                                                                object:self
                                                              userInfo:@{MediaManagerContentChangeTypeKey : @(MediaManagerContentChangeRemove),
                                                                         MediaManagerContentTypeKey : MediaManagerContentTypeVideo,
                                                                         MediaManagerContentKey : key}];
        }];
    }];
}

- (void)removeAllVideos {
    [self removeAllVideosWithCompletionBlock:nil];
}

- (void)removeAllVideosWithCompletionBlock:(void (^)(void))completion {
    NSArray *sortedTimesCopy = [self.videoFilePaths allKeys];
    NSUInteger totalVideos = [sortedTimesCopy count];
    __block NSUInteger videosRemoved = 0;
    
    if (![sortedTimesCopy count]) {
        if (completion) {
            dispatch_async_main_safe (completion);
        }
    }
    
    for (id key in sortedTimesCopy) {
        [self removeVideoForKey:key completion:^(id key) {
            if (++videosRemoved == totalVideos) {
                if (completion) {
                    dispatch_async_main_safe (completion);
                }
            }
        }];
    };
}

#pragma mark saving

- (void)saveVideoToSavedPhotosAlbumForKey:(id)key {
    [self saveVideoToSavedPhotosAlbumForKey:key completion:nil];
}

- (void)saveVideoToSavedPhotosAlbumForKey:(id)key completion:(void (^)(void))completion {
    if (!self.videoFilePaths[key]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot save video for key %@ because it has not been added.", key];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    NSString *filePath = self.videoFilePaths[key][FilePathsVideoPathKey];
    assert (filePath);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        assert (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath));
        UISaveVideoAtPathToSavedPhotosAlbum(filePath,
                                            self,
                                            @selector(video:didFinishSavingWithError:contextInfo:),
                                            (__bridge void *)(completion));
    });
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    assert ([NSThread isMainThread]);

    void(^completion)(void) = (__bridge void(^)(void))contextInfo;
    if (completion) {
        completion ();
    }
}

#pragma mark miscellaneous

- (void)createThumbnailImageForVideo:(AVAsset *)video completion:(void(^)(AVAsset *video, UIImage *thumbnailImage)) completion {
    assert ([video isReadable]);
    assert ([video isPlayable]);
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:video];
    [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *result = [UIImage imageWithCGImage:image];
            dispatch_async_main_safe(^{
                completion (video, result);
            });
        } else {
            assert (NO);
        }
    }];
}

@end
