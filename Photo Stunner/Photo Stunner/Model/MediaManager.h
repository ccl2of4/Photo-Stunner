//
//  ImageManager.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MediaManager : NSObject

@property (readonly, nonatomic) CGSize thumbnailImageMaxSize;

@end

@interface MediaManager (Image)

@property (readonly, nonatomic) NSArray *allImageKeys;

// retrieving
- (void) retrieveImageForKey:(id)key completion:(void(^)(id key, UIImage *image))completion;
- (void) retrieveThumbnailImageForKey:(id)key completion:(void(^)(id key, UIImage *image))completion;

// adding
- (void) addImage:(UIImage *)image forKey:(id)key;
- (void) addImage:(UIImage *)image forKey:(id)key completion:(void(^)(id key, UIImage *image))completion;

// removal
- (void) removeImageForKey:(id)key;
- (void) removeImageForKey:(id)key completion:(void(^)(id key))completion;;
- (void) removeAllImages;
- (void) removeAllImagesWithCompletionBlock:(void(^)(void))completion;

// saving
- (void) saveImageToSavedPhotosAlbumForKey:(id)key;
- (void) saveImageToSavedPhotosAlbumForKey:(id)key completion:(void(^)(void))completion;

@end

@interface MediaManager (Video)

@property (readonly, nonatomic) NSArray *allVideoKeys;

// retrieving
- (void) retrieveVideoForKey:(id)key completion:(void(^)(id key, AVAsset *video))completion;
- (void) retrieveVideoThumbnailImageForKey:(id)key completion:(void(^)(id key, UIImage *image))completion;


// adding
- (void) addVideo:(AVAsset *)video forKey:(id)key;
- (void) addVideo:(AVAsset *)video forKey:(id)key completion:(void(^)(id key, AVAsset *video))completion;

// removal
- (void) removeVideoForKey:(id)key;
- (void) removeVideoForKey:(id)key completion:(void(^)(id key))completion;;
- (void) removeAllVideos;
- (void) removeAllVideosWithCompletionBlock:(void(^)(void))completion;

// saving
- (void) saveVideoToSavedPhotosAlbumForKey:(id)key;
- (void) saveVideoToSavedPhotosAlbumForKey:(id)key completion:(void(^)(void))completion;

@end