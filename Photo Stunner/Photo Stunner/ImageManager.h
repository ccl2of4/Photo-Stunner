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

extern NSString * const ImageManagerSortedTimesChangedNotification;
extern NSString * const ImageManagerSortedTimesRemovedIndexKey;
extern NSString * const ImageManagerSortedTimesAddedIndexKey;

@interface ImageManager : NSObject

+ (ImageManager *) sharedManager;

- (UIImage *) imageForTime:(CMTime)time;
- (void) setImage:(UIImage *)image forTime:(CMTime)time;
- (void) removeImageForTime:(CMTime)time;

@end

@interface ImageManager (SortedTimes)

@property (readonly, nonatomic) NSArray *sortedTimes;

@end
