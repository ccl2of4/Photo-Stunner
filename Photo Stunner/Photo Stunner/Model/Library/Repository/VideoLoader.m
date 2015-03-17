//
//  LibraryLoader.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "VideoLoader.h"
#import <AVFoundation/AVFoundation.h>

#import "NSURLVideoAssetAdapter.h"
#import "ALAssetVideoAssetAdapter.h"

@implementation VideoLoader

NSString const * VideoLoaderModelChangedNotification = @"videoloader model changed notification";

+ (VideoLoader *)sharedInstance {
    static VideoLoader *singleton = nil;
    if (!singleton) {
        singleton = [VideoLoader new];
    }
    return singleton;
}

- (void)loadVideos:(void (^)(NSArray *videos))completion {
    static NSArray *videoNames = nil;
    if (!videoNames) {
        videoNames = @[
            @"1.mp4",@"2.mp4",@"3.mp4",@"4.mp4",@"5.mp4",@"6.mp4",
        ];
    }
    
    NSMutableArray *result = [NSMutableArray new];
    
    for (NSString *videoName in videoNames) {
        NSString *videoPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:videoName];
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
        id<VideoAsset> videoAsset = [[NSURLVideoAssetAdapter alloc] initWithURL:videoURL];
        [result addObject:videoAsset];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        completion (result);
    });
    
}

@end
