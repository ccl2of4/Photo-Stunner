//
//  PreviewBarView.h
//  Photo Stunner
//
//  Created by Connor Lirot on 4/3/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class PlaybackBarView;

@protocol PlaybackBarViewDelegate <NSObject>

@optional
- (BOOL) playbackBarView:(PlaybackBarView *)playbackBarView shouldSeekToTime:(CMTime)time;
- (void) playbackBarView:(PlaybackBarView *)playbackBarView didSeekToTime:(CMTime)time;

@end

@interface PlaybackBarView : UIView

@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) id<PlaybackBarViewDelegate> delegate;

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

@end