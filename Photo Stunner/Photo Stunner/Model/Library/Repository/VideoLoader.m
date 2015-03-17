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
    assert (NO);
}

//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ALAssetsLibraryChangedNotification object:nil];

/*
 - (void) reloadData {
 NSMutableArray *allAssets = [NSMutableArray new];
 [self enumerateGroupsWithCompletion:^(NSArray *groups) {
 for (ALAssetsGroup *group in groups) {
 [self enumerateAssets:group completion:^(NSArray *assets) {
 [allAssets addObjectsFromArray:assets];
 self.assets = allAssets;
 [self.collectionView reloadData];
 }];
 }
 }];
 }
 
 - (void) enumerateAssets:(ALAssetsGroup *)group completion:(void(^)(NSArray *assets))completion {
 NSMutableArray *result = [NSMutableArray new];
 [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
 if (result) {
 [result addObject:asset];
 } else {
 completion (result);
 }
 }];
 }
 
 - (void) enumerateGroupsWithCompletion:(void(^)(NSArray *groups))completion {
 NSMutableArray *result = [NSMutableArray new];
 ALAssetsLibrary *lib = [ALAssetsLibrary new];
 
 [lib enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
 if (group) {
 [group setAssetsFilter:[ALAssetsFilter allVideos]];
 [result addObject:group];
 } else {
 dispatch_async(dispatch_get_main_queue(), ^{
 completion (result);
 });
 }
 } failureBlock:^(NSError *error) {
 assert (NO);
 }];
 }
 */

/*
 - (void) handleNotification:(NSNotification *)notification {
 id userInfo = [notification userInfo];
 if (!userInfo || [userInfo count]) {
 [self reloadData];
 }
 }
 */

@end
