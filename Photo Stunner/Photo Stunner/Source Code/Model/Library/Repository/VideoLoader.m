//
//  LibraryLoader.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "VideoLoader.h"
#import <AVFoundation/AVFoundation.h>

#import "AVAssetVideoAssetAdapter.h"
#import "ALAssetVideoAssetAdapter.h"

@interface VideoLoader ()

@property (nonatomic) ALAssetsLibrary *assetsLibrary;

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
    NSMutableArray *result = [NSMutableArray new];
    
    for (NSString *videoPath in [self videoPathsFromBundle]) {
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
        AVAsset *asset = [AVAsset assetWithURL:videoURL];
        if ([asset isReadable] && [asset isPlayable]) {
            id<VideoAsset> videoAsset = [[AVAssetVideoAssetAdapter alloc] initWithAsset:asset];
            [result addObject:videoAsset];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        completion (result);
    });
}

- (NSArray *)videoPathsFromBundle {
    NSMutableArray *result = [NSMutableArray new];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:bundlePath];
    
    NSString *fileName;
    while ((fileName = [dirEnum nextObject])) {
        if ([[fileName pathExtension] isEqualToString: @"mp4"]) {
            NSString *fullPath = [bundlePath stringByAppendingPathComponent:fileName];
            [result addObject:fullPath];
        }
    }
    return result;
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
