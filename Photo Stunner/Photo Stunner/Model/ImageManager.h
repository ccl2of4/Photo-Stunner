//
//  ImageManager.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@interface ImageManager : NSObject

extern NSString * const ImageManagerSortedTimesChangedNotification;
extern NSString * const ImageManagerSortedTimesRemovedIndexKey;
extern NSString * const ImageManagerSortedTimesAddedIndexKey;

+ (ImageManager *) sharedManager;

@property (readonly, nonatomic) NSArray *sortedTimes;
@property (nonatomic) CGSize thumbnailImageMaxSize;

// retrieving images
- (void) retrieveImageForTime:(CMTime)time completion:(void(^)(CMTime time, UIImage *image))completion;
- (void) retrieveThumbnailImageForTime:(CMTime)time completion:(void(^)(CMTime time, UIImage *image))completion;

// adding images
- (void) addImage:(UIImage *)image forTime:(CMTime)time;
- (void) addImage:(UIImage *)image forTime:(CMTime)time completion:(void(^)(CMTime time, UIImage *image))completion;

// removal
- (void) removeImageForTime:(CMTime)time;
- (void) removeImageForTime:(CMTime)time completion:(void(^)(CMTime time))completion;;

- (void) removeAllImages;
- (void) removeAllImagesWithCompletionBlock:(void(^)(void))completion;

@end
