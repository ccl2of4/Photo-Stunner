//
//  PreviewBarView.m
//  Photo Stunner
//
//  Created by Connor Lirot on 4/3/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "PlaybackBarView.h"

@interface PlaybackBarView ()

@property (nonatomic) NSMutableArray *imageViews;
@property (nonatomic) UIView *trackerView;

@property (nonatomic) NSMutableDictionary *imageIndicatorViews;
@property (nonatomic) NSMutableDictionary *videoIndicatorViews;

@end

@implementation PlaybackBarView

#pragma mark life cycle

- (void) commonInit {
    self.imageViews = [NSMutableArray new];
    self.imageIndicatorViews = [NSMutableDictionary new];
    self.videoIndicatorViews = [NSMutableDictionary new];
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
        NSString *reason = [NSString stringWithFormat:@"Out of range setting image at index %d", index];
        [[NSException exceptionWithName:NSRangeException reason:reason userInfo:nil] raise];
    }
    
    UIImageView *imageView = self.imageViews[index];
    [imageView setImage:image];
}

#pragma mark image indicators

- (void)addImageIndicatorForTime:(CMTime)time {
    Float64 percent = CMTimeGetSeconds(time) / CMTimeGetSeconds([self videoDuration]);
    
    CGFloat width = 3.0f;
    CGFloat height = 3.0f;
    CGFloat x = ([self bounds].origin.x + percent * [self bounds].size.width) - (0.5 * width);
    CGFloat y = CGRectGetMidY([self bounds]) - (0.5 * height);
    
    CGRect frame = CGRectMake(x, y, width, height);
    
    UIView *indicatorView = [[UIView alloc] initWithFrame:frame];
    [indicatorView setBackgroundColor:[UIColor whiteColor]];
    
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
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
    Float64 startPercent = CMTimeGetSeconds(timeRange.start) / CMTimeGetSeconds([self videoDuration]);
    Float64 endPercent = CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange)) / CMTimeGetSeconds([self videoDuration]);
    
    CGFloat width = (endPercent - startPercent) * [self bounds].size.width;
    CGFloat height = 3.0f;
    CGFloat x = ([self bounds].origin.x + startPercent * [self bounds].size.width);
    CGFloat y = CGRectGetMidY([self bounds]) + (0.5 * height);
    
    CGRect frame = CGRectMake(x, y, width, height);
    
    UIView *indicatorView = [[UIView alloc] initWithFrame:frame];
    [indicatorView setBackgroundColor:[UIColor whiteColor]];
    
    NSValue *wrappedTimeRange = [NSValue valueWithCMTimeRange:timeRange];
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

- (void)setCurrentTime:(CMTime)currentTime {
    Float64 percent = CMTimeGetSeconds(currentTime) / CMTimeGetSeconds([self videoDuration]);
    
    CGRect frame = [self.trackerView frame];
    frame.origin.x = ([self bounds].origin.x + percent * [self bounds].size.width) - (0.5 * frame.size.width);
    [self.trackerView setFrame:frame];
    
    _currentTime = currentTime;
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

@end


















