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

@end

#define ImageMangerDirectory [NSTemporaryDirectory() stringByAppendingPathComponent:@"ImageManager"]

@implementation ImageManager

#pragma mark class methods

+ (ImageManager *)sharedManager {
    ImageManager *singleton = nil;
    if (!singleton) {
        singleton = [ImageManager new];
    }
    return singleton;
}

#pragma mark instance methods

- (instancetype) init {
    self = [super init];
    if (self) {
        self.times = [NSMutableDictionary new];
    }
    return self;
}


- (NSArray *)sortedTimes {
    return [self.times allKeys];
}

- (void)setImage:(UIImage *)image forTime:(CMTime)time {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSError *error;
    if ([manager fileExistsAtPath:ImageMangerDirectory]) {
        [manager removeItemAtPath:ImageMangerDirectory error:&error];
        assert (!error);
    }
    [manager createDirectoryAtPath:@"" withIntermediateDirectories:NO attributes:nil error:&error];
    assert (!error);
    
    int currentTime = CFAbsoluteTimeGetCurrent() * 10000;
    NSString *fileName = [NSString stringWithFormat:@"%d.jpg", currentTime];
    NSString *filePath = [ImageMangerDirectory stringByAppendingPathComponent:fileName];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:filePath atomically:NO];
    
    [self.times setObject:filePath forKey:[NSValue valueWithCMTime:time]];
}

- (UIImage *)imageForTime:(CMTime)time {
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    NSString *filePath = [self.times objectForKey:wrappedTime];
    UIImage *result = nil;
    
    if (filePath) {
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
