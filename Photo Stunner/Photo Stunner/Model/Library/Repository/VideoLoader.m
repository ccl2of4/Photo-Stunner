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

@interface VideoLoader ()

@property ALAssetsLibrary *assetsLibrary;

@end

@implementation VideoLoader

NSString * const VideoLoaderModelChangedNotification = @"videoloader model changed notification";

+ (VideoLoader *)sharedInstance {
    static VideoLoader *singleton = nil;
    if (!singleton) {
        singleton = [VideoLoader new];
    }
    return singleton;
}

- (void)loadVideos:(void (^)(NSArray *videos))completion {
    [self loadVideosFromBundle:completion];
}

- (void)loadVideosFromBundle:(void (^)(NSArray *videos))completion {
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

- (void)loadVideosFromPhotosLibrary:(void (^)(NSArray *videos))completion {
    
    if (![self assetsLibrary]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
    
        self.assetsLibrary = [ALAssetsLibrary new];
    }
    NSMutableArray *result = [NSMutableArray new];
    NSMutableArray *groups = [NSMutableArray new];
    
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            [groups addObject:group];
        } else {
            for (ALAssetsGroup *group in groups) {
                [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                    if (asset) {
                        id<VideoAsset> videoAsset = [[ALAssetVideoAssetAdapter alloc] initWithAsset:asset];
                        [result addObject:videoAsset];
                    } else {
                        
                        //this needs to be called on the main thread
                        assert ([NSThread currentThread] == [NSThread mainThread]);
                        completion (result);
                    }
                }];
            }
        }
    } failureBlock:^(NSError *error) {
        assert (NO);
    }];
}

- (void) handleNotification:(NSNotification *)notification {
    id userInfo = [notification userInfo];
    if (!userInfo || [userInfo count]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VideoLoaderModelChangedNotification object:nil];
    }
}

-(void)dealloc {
    if ([self assetsLibrary])
        [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
