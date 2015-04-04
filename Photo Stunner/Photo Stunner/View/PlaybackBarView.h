//
//  PreviewBarView.h
//  Photo Stunner
//
//  Created by Connor Lirot on 4/3/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlaybackBarView : UIView

@property (nonatomic) CMTime videoDuration;

// preview images
@property (nonatomic) NSUInteger numberOfPreviewImages;
- (void) setPreviewImage:(UIImage *)image atIndex:(NSUInteger)index;

// image indicators
@property (nonatomic, readonly) NSArray *imageIndicatorTimes;
- (void) addImageIndicatorForTime:(CMTime)time;
- (void) removeImageIndicatorForTime:(CMTime)time;

// video indicators
@property (nonatomic, readonly) NSArray *videoIndicatorTimeRanges;
- (void) addVideoIndicatorForTimeRange:(CMTimeRange)timeRange;
- (void) changeVideoIndicatorForTimeRange:(CMTimeRange)oldTimeRange toTimeRange:(CMTimeRange)newTimeRange;
- (void) removeVideoIndicatorForTimeRange:(CMTimeRange)timeRange;

// tracking playback
@property (nonatomic) CMTime currentTime;

@end