//
//  PreviewBarView.h
//  Photo Stunner
//
//  Created by Connor Lirot on 4/3/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PreviewBarView : UIView

@property (nonatomic) CMTime videoDuration;


@property (nonatomic) NSUInteger numberOfPreviewImages;
- (void) setPreviewImage:(UIImage *)image atIndex:(NSUInteger)index;


@property (nonatomic, readonly) NSArray *imageIndicatorTimes;
- (void) addImageIndicatorForTime:(CMTime)time;
- (void) removeImageIndicatorForTime:(CMTime)time;


@property (nonatomic, readonly) NSArray *videoIndicatorTimeRanges;
- (void) addVideoIndicatorForTimeRange:(CMTimeRange)timeRange;
- (void) addVideoIndicatorForStartTime:(CMTime)startTime
                             updateBlock:(BOOL(^)(CMTime currentDuration))updateBlock
                         updateFrequency:(float)seconds;
- (void) removeVideoIndicatorForTimeRange:(CMTimeRange)timeRange;

@end