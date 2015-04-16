//
//  PreviewBarView.m
//  Photo Stunner
//
//  Created by Connor Lirot on 4/3/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "PlaybackBarView.h"
#import "PhotoStunnerConstants.h"

@interface PlaybackBarView ()

@property (nonatomic) NSMutableArray *imageViews;
@property (nonatomic) UIView *trackerView;

@property (nonatomic) NSMutableDictionary *imageIndicatorViews;
@property (nonatomic) NSMutableDictionary *videoIndicatorViews;

@property (nonatomic) id periodicTimeObserver;

@end

@implementation PlaybackBarView

#pragma mark life cycle

- (void) commonInit {
    self.imageViews = [NSMutableArray new];
    self.imageIndicatorViews = [NSMutableDictionary new];
    self.videoIndicatorViews = [NSMutableDictionary new];
    
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUIGestureRecognizerRecognized:)];
    [self addGestureRecognizer:gr];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat startX = [self bounds].origin.x;
    CGFloat width = [self bounds].size.width / [self.imageViews count];
    CGFloat height = [self bounds].size.height;
    CGFloat y = 0;
    
    [self.imageViews enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
        CGRect frame = [imageView frame];
        CGFloat x = startX + idx * width;
        frame.size = CGSizeMake(width, height);
        frame.origin = CGPointMake(x,y);
        [imageView setFrame:frame];
    }];
}

- (NSArray *)imageIndicatorTimes {
    return [self.imageIndicatorViews allKeys];
}

- (NSArray *)videoIndicatorTimeRanges {
    return [self.videoIndicatorViews allKeys];
}

#pragma mark UI events

- (void) handleUIGestureRecognizerRecognized:(id)sender {
    CGPoint location = [sender locationInView:self];
    CGFloat percent = location.x / self.bounds.size.width;
    CMTime soughtTime = CMTimeMultiplyByFloat64([self.player.currentItem duration], percent);
    
    if (![self.delegate respondsToSelector:@selector(playbackBarView:shouldSeekToTime:)] ||
        [self.delegate playbackBarView:self shouldSeekToTime:soughtTime]) {
                
        [self.player pause];
        
        [self.player seekToTime:soughtTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            if ([self.delegate respondsToSelector:@selector(playbackBarView:didSeekToTime:)]) {
                [self.delegate playbackBarView:self didSeekToTime:soughtTime];
            }
        }];
    }
}

#pragma mark preview images

- (void)setNumberOfPreviewImages:(NSUInteger)numberOfPreviewImages {

    // populate the array with the appropriate number of image views
    NSMutableArray *newImageViews = [NSMutableArray new];
    NSRange reusedRange = NSMakeRange(0, MIN(numberOfPreviewImages,[self.imageViews count]));
    NSRange discardedRange = NSMakeRange(reusedRange.length, [self.imageViews count] - reusedRange.length);
    NSRange newRange = NSMakeRange(reusedRange.length, numberOfPreviewImages - reusedRange.length);

    [[NSIndexSet indexSetWithIndexesInRange:reusedRange] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [newImageViews addObject:self.imageViews[idx]];
    }];
    [[NSIndexSet indexSetWithIndexesInRange:discardedRange] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.imageViews[idx] removeFromSuperview];
    }];
    [[NSIndexSet indexSetWithIndexesInRange:newRange] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        UIImageView *imageView = [UIImageView new];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView setClipsToBounds:YES];
        [newImageViews addObject:imageView];
        [self addSubview:imageView];
    }];
    
    self.imageViews = newImageViews;
    
    _numberOfPreviewImages = numberOfPreviewImages;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setPreviewImage:(UIImage *)image atIndex:(NSUInteger)index {
    if (index >= [self numberOfPreviewImages]) {
        NSString *reason = [NSString stringWithFormat:@"Out of range setting image at index %lu", (unsigned long)index];
        [[NSException exceptionWithName:NSRangeException reason:reason userInfo:nil] raise];
    }
    
    UIImageView *imageView = self.imageViews[index];
    [imageView setImage:image];
}

#pragma mark image indicators

- (void)addImageIndicatorForTime:(CMTime)time {
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    if (self.imageIndicatorViews[wrappedTime]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot add image indicator for time %@ because an indicator for that time already exists.", wrappedTime];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    Float64 percent = CMTimeGetSeconds(time) / CMTimeGetSeconds([self.player.currentItem duration]);
    
    CGFloat height = 5.0f;
    CGFloat width = height;
    CGFloat x = ([self bounds].origin.x + percent * [self bounds].size.width) - (0.5 * width);
    CGFloat y = CGRectGetMinY([self bounds]);
    
    CGRect frame = CGRectMake(x, y, width, height);
    
    UIView *indicatorView = [[UIView alloc] initWithFrame:frame];
    [indicatorView setBackgroundColor:ImageColor];
    indicatorView.layer.borderWidth = 1;
    indicatorView.layer.borderColor = [UIColor colorWithWhite:.5 alpha:.5].CGColor;
    
    self.imageIndicatorViews[wrappedTime] = indicatorView;
    [self addSubview:indicatorView];
}

- (void)removeImageIndicatorForTime:(CMTime)time {
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    UIView *indicatorView = self.imageIndicatorViews[wrappedTime];

    if (!indicatorView) {
        NSString *reason = [NSString stringWithFormat:@"no image indicator for time %@", wrappedTime];
        [[NSException exceptionWithName:NSRangeException reason:reason userInfo:nil] raise];
    }
    
    [indicatorView removeFromSuperview];
    [self.imageIndicatorViews removeObjectForKey:wrappedTime];
}

#pragma mark video indicators

- (void)addVideoIndicatorForTimeRange:(CMTimeRange)timeRange {
    
    NSValue *wrappedTimeRange = [NSValue valueWithCMTimeRange:timeRange];
    if (self.videoIndicatorViews[wrappedTimeRange]) {
        NSString *reason = [NSString stringWithFormat:@"Cannot add video indicator for time range %@ because an indicator for that time range already exists.", wrappedTimeRange];
        [[NSException exceptionWithName:NSGenericException reason:reason userInfo:nil] raise];
    }
    
    Float64 startPercent = CMTimeGetSeconds(timeRange.start) / CMTimeGetSeconds([self.player.currentItem duration]);
    Float64 endPercent = CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange)) / CMTimeGetSeconds([self.player.currentItem duration]);
    
    CGFloat width = (endPercent - startPercent) * [self bounds].size.width;
    CGFloat height = 5.0f;
    CGFloat x = ([self bounds].origin.x + startPercent * [self bounds].size.width);
    CGFloat y = CGRectGetMaxY([self bounds]) - height;
    
    CGRect frame = CGRectMake(x, y, width, height);
    
    UIView *indicatorView = [[UIView alloc] initWithFrame:frame];
    [indicatorView setBackgroundColor:VideoColor];
    indicatorView.layer.borderWidth = 1;
    indicatorView.layer.borderColor = [UIColor colorWithWhite:.5 alpha:.5].CGColor;
    
    self.videoIndicatorViews[wrappedTimeRange] = indicatorView;
    [self addSubview:indicatorView];
}

- (void)removeVideoIndicatorForTimeRange:(CMTimeRange)timeRange {
    NSValue *wrappedTimeRange = [NSValue valueWithCMTimeRange:timeRange];
    UIView *indicatorView = self.videoIndicatorViews[wrappedTimeRange];
    
    if (!indicatorView) {
        NSString *reason = [NSString stringWithFormat:@"no video indicator for time range %@", wrappedTimeRange];
        [[NSException exceptionWithName:NSRangeException reason:reason userInfo:nil] raise];
    }
    
    [indicatorView removeFromSuperview];
    [self.videoIndicatorViews removeObjectForKey:wrappedTimeRange];
}

// might want to make this more fancy in the future
- (void)changeVideoIndicatorForTimeRange:(CMTimeRange)oldTimeRange toTimeRange:(CMTimeRange)newTimeRange {
    [self removeVideoIndicatorForTimeRange:oldTimeRange];
    [self addVideoIndicatorForTimeRange:newTimeRange];
}

- (void) updateTrackerView:(CMTime)time {
    Float64 percent = CMTimeGetSeconds(time) / CMTimeGetSeconds([self.player.currentItem duration]);
    CGRect frame = [self.trackerView frame];
    frame.origin.x = ([self bounds].origin.x + percent * [self bounds].size.width) - (0.5 * frame.size.width);
    [self.trackerView setFrame:frame];
}

- (UIView *)trackerView {
    if (!_trackerView) {

    CGFloat width = 2.0f;
    CGFloat height = [self bounds].size.height;
    CGFloat x = [self bounds].origin.x - (0.5 * width);
    CGFloat y = [self bounds].origin.y;
    
    CGRect frame = CGRectMake(x, y, width, height);
    
    UIView *trackerView = [[UIView alloc] initWithFrame:frame];
    [trackerView setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:trackerView];
        
        _trackerView = trackerView;
    }
    
    return _trackerView;
}

#pragma mark miscellaneous

- (void)setPlayer:(AVPlayer *)player {
    [self setPeriodicTimeObserverEnabled:NO];
    _player = player;
    [self setPeriodicTimeObserverEnabled:YES];
}

- (void) setPeriodicTimeObserverEnabled:(BOOL)enabled {
    if (enabled == !![self periodicTimeObserver]) {
        return;
    }
    
    if (enabled) {
        assert (![self periodicTimeObserver]);

        __weak typeof (self) weakSelf = self;
        self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 100) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            [weakSelf updateTrackerView:time];
        }];
    }
    
    else {
        assert ([self periodicTimeObserver]);
        [self.player removeTimeObserver:[self periodicTimeObserver]];
        self.periodicTimeObserver = nil;
    }
}
@end