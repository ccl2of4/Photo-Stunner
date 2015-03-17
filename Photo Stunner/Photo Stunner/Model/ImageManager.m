//
//  ImageManager.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "ImageManager.h"
#import <AVFoundation/AVFoundation.h>


@interface ImageManager ()

@property NSMutableDictionary *times;
@property (readwrite, nonatomic) NSMutableArray *sortedTimes;

@end


@implementation ImageManager

NSString * const ImageManagerSortedTimesChangedNotification = @"image manager sortedtimes changed notification";
NSString * const ImageManagerSortedTimesRemovedIndexKey = @"image manager sortedtimes removed index key";
NSString * const ImageManagerSortedTimesAddedIndexKey = @"image manager sortedtimes added index key";
#define ImageManagerDirectory [NSTemporaryDirectory() stringByAppendingPathComponent:@"ImageManager"]

#pragma mark class methods

ImageManager *singleton = nil;
+ (ImageManager *)sharedManager {
    if (!singleton) {
        singleton = [ImageManager new];
    }
    return singleton;
}

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

#pragma mark instance methods

- (instancetype) init {        
    self = [super init];
    if (self) {
        [self clearDirectory];
        self.times = [NSMutableDictionary new];
        self.sortedTimes = [NSMutableArray new];
    }
    return self;
}

- (void)removeAllImages {
    for (NSValue *time in [self.sortedTimes copy]) {
        [self removeImageForTime:[time CMTimeValue]];
    }
    assert ([self.times count] == 0);
    assert ([self.sortedTimes count] == 0);
}

- (void)clearDirectory {
    assert ([self.times count] == 0);
    assert ([self.sortedTimes count] == 0);
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSError *error;
    if ([manager fileExistsAtPath:ImageManagerDirectory]) {
        [manager removeItemAtPath:ImageManagerDirectory error:&error];
        assert (!error);
    }
    [manager createDirectoryAtPath:ImageManagerDirectory withIntermediateDirectories:NO attributes:nil error:&error];
    assert (!error);
}

- (void)setImage:(UIImage *)image forTime:(CMTime)time {
    
    uint32_t currentTime = arc4random();
    
    NSString *fileName;
    NSString *filePath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    do {
        fileName = [NSString stringWithFormat:@"%u.jpg", currentTime];
        filePath = [ImageManagerDirectory stringByAppendingPathComponent:fileName];
    } while ([fileManager fileExistsAtPath:filePath]);
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:NO];
    
    assert ([fileManager fileExistsAtPath:filePath]);
    
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    [self.times setObject:filePath forKey:wrappedTime];
    [self.sortedTimes addObject:wrappedTime];
    [self.sortedTimes sortUsingComparator:[ImageManager comparatorForSorting]];
    NSUInteger addedIndex = [self.sortedTimes indexOfObject:wrappedTime];
    
    assert (addedIndex != NSNotFound);
    [[NSNotificationCenter defaultCenter] postNotificationName:ImageManagerSortedTimesChangedNotification
                                                        object:@{ImageManagerSortedTimesAddedIndexKey : @(addedIndex)}];
}

- (void)removeImageForTime:(CMTime)time {
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    NSString *filePath = [self.times objectForKey:wrappedTime];
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    assert (filePath);
    [fileManager removeItemAtPath:filePath error:&error];
    assert (!error);
    
    NSUInteger removedIndex = [self.sortedTimes indexOfObject:wrappedTime];
    
    [self.times removeObjectForKey:wrappedTime];
    [self.sortedTimes removeObject:wrappedTime];
    
    assert(removedIndex != NSNotFound);
    [[NSNotificationCenter defaultCenter] postNotificationName:ImageManagerSortedTimesChangedNotification
                                                        object:@{ImageManagerSortedTimesRemovedIndexKey : @(removedIndex)}];
}

- (UIImage *)imageForTime:(CMTime)time {
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    NSString *filePath = [self.times objectForKey:wrappedTime];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    UIImage *result = nil;
    
    if (filePath) {
        assert ([fileManager fileExistsAtPath:filePath]);
        
        result = [UIImage imageWithContentsOfFile:filePath];
        assert (result);
        
        if (!result) {
            result = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath]];
            assert (result);
        }
    }
    
    return result;
}

@end
