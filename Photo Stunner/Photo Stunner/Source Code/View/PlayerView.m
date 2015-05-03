//
//  PlayerView.m
//  Photo Stunner
//
//  Created by Connor Lirot on 4/3/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "PlayerView.h"
#import "FlashView.h"

@interface PlayerView ()

@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) UIImageView *previewImageView;
@property (nonatomic) UIView *playbackView;
@property (nonatomic) FlashView *flashView;

@property (nonatomic) CMTimeRange touchedTimeRange;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) id periodicTimeObserver;

@end

@implementation PlayerView

#pragma mark life cycle

- (void) commonInit {
    self.playbackView = [UIView new];
    self.flashView = [FlashView new];
    self.previewImageView = [UIImageView new];
    self.touchedTimeRange = kCMTimeRangeInvalid;

    [self.previewImageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.flashView setBackgroundColor:[UIColor lightGrayColor]];
    
    [self addSubview:self.previewImageView];
    [self addSubview:self.playbackView];
    [self addSubview:self.flashView];
    
    UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleUIGestureRecognizerRecognized:)];
    [gr setMinimumPressDuration:0.0];
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
    [self.previewImageView setFrame:[self bounds]];
    [self.playbackView setFrame:[self bounds]];
    [self.playerLayer setFrame:[self.playbackView.layer bounds]];
    [self.flashView setFrame:[self.playerLayer videoRect]];
}

#pragma mark UI events

- (void)handleUIGestureRecognizerRecognized:(id)sender {
    // touch video
    if ([sender isKindOfClass:[UILongPressGestureRecognizer class]] && [sender view] == self) {
        UILongPressGestureRecognizer *gr = sender;
        
        // touch down
        if ([gr state] == UIGestureRecognizerStateBegan) {
            assert (CMTimeRangeEqual(self.touchedTimeRange, kCMTimeRangeInvalid));
            self.touchedTimeRange = CMTimeRangeMake(self.player.currentTime, kCMTimeIndefinite);
            
            assert (![self timer]);
            self.timer = [NSTimer scheduledTimerWithTimeInterval:CMTimeGetSeconds(self.minimumVideoDuration) target:self selector:@selector(handleTimerFired:) userInfo:nil repeats:NO];
        }
        
        
        // touch up
        else if ([gr state] == UIGestureRecognizerStateEnded) {
            
            // sometimes the gesture recognizer will get to StateEnded without ever getting to StateBegan.
            // in that case, we need to ignore the entire gesture
            if (CMTimeRangeEqual(self.touchedTimeRange, kCMTimeRangeInvalid)) {
                return;
            }
            
            CMTimeRange oldTimeRange = self.touchedTimeRange;
            self.touchedTimeRange = CMTimeRangeMake(self.touchedTimeRange.start, CMTimeSubtract(self.player.currentTime, self.touchedTimeRange.start));
            
            // didn't hold down long enough -- take out an image
            if ([self.timer isValid]) {
                CMTime time = [self.player currentTime];
                if ([self.delegate playerView:self shouldFlashForImageAtTime:time]) {
                   
                    // flashView's frame might not be set correctly if layoutSubviews was
                    // only called before self.playerLayer's videoRect was established
                    [self setNeedsLayout];
                    [self layoutIfNeeded];
                    
                    [self.flashView flash];
                }
                [self.delegate playerView:self didSelectImageAtTime:time];
                
            // take out video
            } else {

                if (CMTIME_COMPARE_INLINE(self.touchedTimeRange.duration, >, self.minimumVideoDuration)) {
                    [self.delegate playerView:self didUpdateVideoSelection:self.touchedTimeRange oldTimeRange:oldTimeRange finished:YES];
                } else {
                    [self.delegate playerView:self didCancelVideoSelection:oldTimeRange];
                }
                [self setPeriodicTimeObserverEnabled:NO];
            }
            
            assert (![self periodicTimeObserver]);
            [self.timer invalidate];
            self.timer = nil;
            self.touchedTimeRange = kCMTimeRangeInvalid;
        }
        
        else {
            // handle this
        }
    } else {
        assert (NO);
    }
}

// when this method is called it means the user held down long enough to take out a video, so we can rule out
// counting this as a tap instead of a press
- (void)handleTimerFired:(id)sender {
    self.touchedTimeRange = CMTimeRangeMake(self.touchedTimeRange.start, CMTimeSubtract(self.player.currentTime, self.touchedTimeRange.start));
    [self.delegate playerView:self didStartVideoSelection:self.touchedTimeRange];
    [self setPeriodicTimeObserverEnabled:YES];
}

#pragma mark logic

- (void) setPeriodicTimeObserverEnabled:(BOOL)enabled {
    if (enabled == !![self periodicTimeObserver]) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    
    if (enabled) {
        assert (![self periodicTimeObserver]);
        self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 100) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
            assert (!CMTimeRangeEqual(weakSelf.touchedTimeRange, kCMTimeRangeInvalid));
            
            CMTimeRange oldTimeRange = weakSelf.touchedTimeRange;
            weakSelf.touchedTimeRange = CMTimeRangeMake(weakSelf.touchedTimeRange.start, CMTimeSubtract(time, weakSelf.touchedTimeRange.start));
            [weakSelf.delegate playerView:weakSelf didUpdateVideoSelection:weakSelf.touchedTimeRange oldTimeRange:oldTimeRange finished:NO];
            
        }];
    }
    
    else {
        assert ([self periodicTimeObserver]);
        [self.player removeTimeObserver:[self periodicTimeObserver]];
        self.periodicTimeObserver = nil;
    }
}

- (void)setPlayer:(AVPlayer *)player {
    [self.playerLayer removeFromSuperlayer];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [self.playbackView.layer addSublayer:self.playerLayer];
    
    _player = player;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setPreviewImage:(UIImage *)thumbnailImage {
    [self.previewImageView setImage:thumbnailImage];
}

- (UIImage *)previewImage {
    return [self.previewImageView image];
}

@end
