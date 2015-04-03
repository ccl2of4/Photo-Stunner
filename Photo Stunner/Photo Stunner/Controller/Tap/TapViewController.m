//
//  TapViewController.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "TapViewController.h"
#import "MediaManager.h"
#import "MediaManager+CMTimeImageKeys.h"
#import "MediaManager+CMTimeRangeVideoKeys.h"
#import "ThumbnailsViewController.h"
#import "FlashView.h"
#import "UICollectionViewImageCell.h"
#import "PreviewBarView.h"
#import <AVFoundation/AVFoundation.h>

@interface TapViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *playbackView;
@property (weak, nonatomic) IBOutlet UIView *playerLayerView;
@property (weak, nonatomic) IBOutlet PreviewBarView *previewBarView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *backStepButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardStepButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) FlashView *flashView;
@property (weak, nonatomic) UIView *playbackTrackerView;
@property (weak, nonatomic) AVPlayerLayer *playerLayer;

@property (nonatomic) AVAssetImageGenerator *imageGenerator;
@property (nonatomic) AVAssetImageGenerator *previewImageGenerator;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) id periodicTimeObserver;

@property (nonatomic) MediaManager *mediaManager;
@property (nonatomic) CMTimeRange touchedTimeRange;

@end

@implementation TapViewController {
    dispatch_once_t _firstVisitToken;
}

static void * PlayerStatusObservingContext = &PlayerStatusObservingContext;
static void * PlayerRateObservingContext = &PlayerRateObservingContext;
static NSString * const CellReuseIdentifier = @"cell";
static const NSUInteger NumberOfPreviewImages = 10;
#define MaxTapDuration CMTimeMake(1,2)

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(handleUIControlEventTouchUpInside:)];
    [rightBarButtonItem setEnabled:NO];
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
    
    [self.imageView setImage:[self.videoAsset thumbnail]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:MediaManagerContentChangedNotification object:self.mediaManager];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self playbackTrackerView];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_once(&_firstVisitToken, ^{
        [self.player play];
        [self generatePreviewImages];
    });
    
    [self setPeriodicTimeObserverEnabled:YES];
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:PlayerRateObservingContext];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.player pause];
    [self setPeriodicTimeObserverEnabled:NO];
    [self removeObserver:self forKeyPath:@"player.rate"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.imageGenerator cancelAllCGImageGeneration];
    [self.previewImageGenerator cancelAllCGImageGeneration];
}

#pragma mark UI events

- (IBAction)handleUIGestureRecognizerRecognized:(id)sender {
    
    // touch video
    if ([sender isKindOfClass:[UILongPressGestureRecognizer class]] && [sender view] == self.playbackView) {
        UILongPressGestureRecognizer *gr = sender;
        
        // touch down
        if ([gr state] == UIGestureRecognizerStateBegan) {
            self.touchedTimeRange = CMTimeRangeMake(self.player.currentTime, kCMTimeIndefinite);
        }
        
        
        // touch up
        else if ([gr state] == UIGestureRecognizerStateEnded) {
            self.touchedTimeRange = CMTimeRangeMake(self.touchedTimeRange.start, CMTimeSubtract(self.player.currentTime, self.touchedTimeRange.start));
            
            
            // extract video
            if (CMTIME_COMPARE_INLINE(self.touchedTimeRange.duration, >, MaxTapDuration)) {
                [self extractVideoForTimeRange:self.touchedTimeRange];
            }
            
            
            // extract image
            else {
                CMTime time = [self.player currentTime];
                if ([self extractImageAtTime:time]) {
                    [self.flashView flash];
                }
            }
        }

        else {
            // handle this
        }
       
    // tapped preview bar
    } else if ([sender isKindOfClass:[UITapGestureRecognizer class]] && [sender view] == self.previewBarView){
        
        CGPoint location = [sender locationInView:self.previewBarView];
        CGFloat percent = location.x / self.previewBarView.bounds.size.width;
        CMTime soughtTime = CMTimeMultiplyByFloat64([self.player.currentItem duration], percent);
        
        [self.player pause];
        [self.player seekToTime:soughtTime];
    } else {
        assert (NO);
    }
}

- (IBAction)handleUIControlEventTouchUpInside:(id)sender{
    
    // "Next" button
    if (sender == self.navigationItem.rightBarButtonItem) {
        
        assert(self.navigationController);
        ThumbnailsViewController *thumbnailsViewController = [ThumbnailsViewController new];
        [thumbnailsViewController setMediaManager:[self mediaManager]];
        [self.navigationController pushViewController:thumbnailsViewController animated:YES];
    
    // << button
    } else if (sender == self.backStepButton) {
        
        [self.player pause];
        CMTime currentTime = [self.player currentTime];
        CMTime soughtTime = CMTimeSubtract(currentTime, [self timePerFrame]);
        [self.player seekToTime:soughtTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
       
    // >> button
    } else if (sender == self.forwardStepButton) {
        
        [self.player pause];
        CMTime currentTime = [self.player currentTime];
        CMTime soughtTime = CMTimeAdd(currentTime, [self timePerFrame]);
        [self.player seekToTime:soughtTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    // play button
    } else if (sender == self.playButton) {
        
        if ([self.player rate]) {
            [self.player pause];
        } else {
            [self.player play];
        }
        
    } else {
        assert (NO);
    }
}

#pragma mark video generation

- (BOOL)extractVideoForTimeRange:(CMTimeRange)timeRange {
    
    NSValue *wrappedTimeRange = [NSValue valueWithCMTimeRange:self.touchedTimeRange];
    if ([[self.mediaManager sortedVideoKeys] containsObject:wrappedTimeRange]) {
        return NO;
    }
    
    // make asset
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSError *error;
    [composition insertTimeRange:timeRange ofAsset:self.player.currentItem.asset atTime:kCMTimeZero error:&error];
    assert (!error);
    
    // add to media manager
    [self.mediaManager addVideo:composition forKey:wrappedTimeRange];
    
    return YES;
}


#pragma mark image generation

- (BOOL) extractImageAtTime:(CMTime)time {

    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    if ([[self.mediaManager sortedImageKeys] containsObject:wrappedTime]) {
        return NO;
    }
    
    __weak typeof (self) weakSelf = self;
    NSArray *times =  @[wrappedTime];
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef cgimg, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if ( result == AVAssetImageGeneratorSucceeded ) {
            assert (!error);
            assert (cgimg);
            UIImage *image = [UIImage imageWithCGImage:cgimg];
            assert (image);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                assert (CMTIME_COMPARE_INLINE(time, ==, requestedTime));
                [weakSelf.mediaManager addImage:image forKey:[NSValue valueWithCMTime:time]];
            });
            
        } else {
            // generation failed. ignore silently
        }
    }];
    
    return YES;
}

- (AVAssetImageGenerator *)imageGenerator {
    if (!_imageGenerator) {
        AVAsset *asset = [self.videoAsset asset];
        _imageGenerator= [[AVAssetImageGenerator alloc] initWithAsset:asset];
        [_imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
        [_imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    }
    return _imageGenerator;
}

- (MediaManager *)mediaManager {
    if (!_mediaManager) {
        _mediaManager = [MediaManager new];
    }
    return _mediaManager;
}

#pragma mark preview images

- (void)generatePreviewImages {
    NSArray *times = [self timesForPreviewImages];
    [self.previewBarView setNumberOfPreviewImages:[times count]];
    [self.previewBarView setVideoDuration:CMTimeMakeWithSeconds([self.videoAsset duration], 30)];
    
    [self.previewImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef cgimg, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        
        // even if the generation was unsuccessful, add a UIImage as a placeholder
        UIImage *image = [UIImage imageWithCGImage:cgimg];
        NSValue *wrappedTime = [NSValue valueWithCMTime:requestedTime];
        NSUInteger idx = [times indexOfObject:wrappedTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.previewBarView setPreviewImage:image atIndex:idx];
        });
    }];
}

- (AVAssetImageGenerator *)previewImageGenerator {
    if (!_previewImageGenerator) {
        AVAsset *asset = [self.videoAsset asset];
        _previewImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        
        [self.view layoutIfNeeded];
        CGSize maximumSize = [self maximumSizeForPreviewImages];
        
        [_previewImageGenerator setMaximumSize:maximumSize];
    }
    return _previewImageGenerator;
}

- (CGSize)maximumSizeForPreviewImages {
    CGSize size = self.previewBarView.bounds.size;
    size.width /= NumberOfPreviewImages;
    return size;
}

- (NSArray *)timesForPreviewImages {
    NSIndexSet *indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, NumberOfPreviewImages)];
    NSMutableArray *times = [NSMutableArray new];
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Float64 seconds = [self.videoAsset duration] * idx / NumberOfPreviewImages;
        CMTime time = CMTimeMakeWithSeconds(seconds, 30);
        NSValue *wrappedTime = [NSValue valueWithCMTime:time];
        [times addObject:wrappedTime];
    }];
    return times;
}

#pragma mark playback

- (void) setPeriodicTimeObserverEnabled:(BOOL)enabled {
    if (enabled == !![self periodicTimeObserver]) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    
    if (enabled) {
        assert (![self periodicTimeObserver]);
        self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 100) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            CMTime vidLength = [weakSelf.player.currentItem duration];
            Float64 percent = CMTimeGetSeconds(time) / CMTimeGetSeconds(vidLength);
            
            CGRect frame = [weakSelf.playbackTrackerView frame];
            CGRect previewBarCollectionViewFrame = [weakSelf.previewBarView frame];
            frame.origin.x = (previewBarCollectionViewFrame.origin.x + percent * previewBarCollectionViewFrame.size.width) - (0.5 * frame.size.width);
            [weakSelf.playbackTrackerView setFrame:frame];
        }];
    }
    
    else {
        assert ([self periodicTimeObserver]);
        [self.player removeTimeObserver:[self periodicTimeObserver]];
        self.periodicTimeObserver = nil;
    }
}

- (AVPlayer *)player {
    if (!_player) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:[self.videoAsset asset]];
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        [player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
        _player = player;
        
        [self.playerLayer setPlayer:player];
    }
    
    return _player;
}

- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:nil];
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        
        [self.playerLayerView.layer addSublayer:playerLayer];
        [playerLayer setFrame:[self.playerLayerView.layer bounds]];
        
        _playerLayer = playerLayer;
    }
    return _playerLayer;
}

- (FlashView *)flashView {
    if (!_flashView) {
        FlashView *flashView = [FlashView new];
        [flashView setBackgroundColor:[UIColor grayColor]];
        CGRect frame = [self.playerLayer videoRect];
        [flashView setFrame:frame];
        [self.playbackView addSubview:flashView];
        
        _flashView = flashView;
    }
    return _flashView;
}

- (UIView *)playbackTrackerView {
    if (!_playbackTrackerView) {
        CGRect previewBarCollectionViewFrame = [self.previewBarView frame];
        CGFloat width = 2.0f;
        CGFloat height = previewBarCollectionViewFrame.size.height;
        CGFloat x = previewBarCollectionViewFrame.origin.x - (0.5 * width);
        CGFloat y = previewBarCollectionViewFrame.origin.y;
        
        CGRect frame = CGRectMake(x, y, width, height);
        
        UIView *playbackTrackerView = [[UIView alloc] initWithFrame:frame];
        [playbackTrackerView setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:playbackTrackerView];
        
        _playbackTrackerView = playbackTrackerView;
    }
    return _playbackTrackerView;
}

- (CMTime) timePerFrame {
    AVAsset *asset = [self.videoAsset asset];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CMTime timePerFrame = CMTimeMake(1,[track nominalFrameRate]);
    return timePerFrame;
}

#pragma mark observer methods

- (void)handleNotification:(NSNotification *)notification {
    if ([notification name] == MediaManagerContentChangedNotification) {
        assert ([notification object] == [self mediaManager]);
        NSDictionary *userInfo = [notification userInfo];
        
        id key = userInfo[MediaManagerContentKey]; assert (key);
        NSString *contentType = userInfo[MediaManagerContentTypeKey]; assert (contentType);
        NSNumber *changeTypeNum = userInfo[MediaManagerContentChangeTypeKey]; assert (changeTypeNum);
        
        MediaManagerContentChangeType changeType = [changeTypeNum unsignedIntValue];
        
        // video
        if ([MediaManagerContentTypeVideo isEqualToString:contentType]) {
            
            // added
            if (MediaManagerContentChangeAdd == changeType) {
                [self.previewBarView addVideoIndicatorForTimeRange:[key CMTimeRangeValue]];
                
            // removed
            } else if (MediaManagerContentChangeRemove == changeType) {
                [self.previewBarView removeVideoIndicatorForTimeRange:[key CMTimeRangeValue]];
                
            } else {
                assert (NO);
            }
        }
        
        // image
        else if ([MediaManagerContentTypeImage isEqualToString:contentType]) {
            
            // added
            if (MediaManagerContentChangeAdd == changeType) {
                [self.previewBarView addImageIndicatorForTime:[key CMTimeValue]];
                
            // removed
            } else if (MediaManagerContentChangeRemove == changeType) {
                [self.previewBarView removeImageIndicatorForTime:[key CMTimeValue]];
                
            } else {
                assert (NO);
            }
            
        } else {
            assert (NO);
        }
        
        // if the user deletes all media, come back to the tap screen to get more
        if (![[self.mediaManager sortedImageKeys] count] && ![[self.mediaManager sortedVideoKeys] count]) {
            [self.navigationController popToViewController:self animated:YES];
        }
        
        // don't go to the next screen if there are no photos/videos pulled out
        BOOL rightBarButtonItemEnabled = ([[self.mediaManager sortedImageKeys] count] + [[self.mediaManager sortedVideoKeys] count]) > 0;
        [self.navigationItem.rightBarButtonItem setEnabled:rightBarButtonItemEnabled];
        
    } else {
        assert (NO);
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (PlayerRateObservingContext == context) {
        assert ([NSThread isMainThread]);
        BOOL isPlaying = ![[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        [self.playButton setSelected:!isPlaying];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end