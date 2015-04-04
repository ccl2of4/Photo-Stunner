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
#import "PlaybackBarView.h"
#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface TapViewController () <UIGestureRecognizerDelegate, PlayerViewDelegate>

@property (weak, nonatomic) IBOutlet PlaybackBarView *playbackBarView;
@property (weak, nonatomic) IBOutlet UIButton *backStepButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardStepButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet PlayerView *playerView;

@property (nonatomic, readonly) AVPlayer *player;
@property (nonatomic) AVAssetImageGenerator *imageGenerator;
@property (nonatomic) AVAssetImageGenerator *previewImageGenerator;
@property (nonatomic) id periodicTimeObserver;

@property (nonatomic) MediaManager *mediaManager;

@end

@implementation TapViewController {
    dispatch_once_t _firstVisitToken;
}

static void * PlayerStatusObservingContext = &PlayerStatusObservingContext;
static void * PlayerRateObservingContext = &PlayerRateObservingContext;
static NSString * const CellReuseIdentifier = @"cell";
static const NSUInteger NumberOfPreviewImages = 10;
#define MinimumVideoDuration CMTimeMake(1,2)

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(handleUIControlEventTouchUpInside:)];
    [rightBarButtonItem setEnabled:NO];
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
    
    [self.playerView setThumbnailImage:[self.videoAsset thumbnail]];
    [self.playerView setMinimumVideoDuration:MinimumVideoDuration];
    [self.playerView setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:MediaManagerContentChangedNotification object:self.mediaManager];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    dispatch_once(&_firstVisitToken, ^{
        [self generatePreviewImages];
        [self.player play];
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
    
    // tapped preview bar
    if ([sender isKindOfClass:[UITapGestureRecognizer class]] && [sender view] == self.playbackBarView){
        
        CGPoint location = [sender locationInView:self.playbackBarView];
        CGFloat percent = location.x / self.playbackBarView.bounds.size.width;
        CMTime soughtTime = CMTimeMultiplyByFloat64([self.player.currentItem duration], percent);
        
        [self.player pause];
        [self.player seekToTime:soughtTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
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

- (void) updateNextButtonVisibility {
    BOOL rightBarButtonItemEnabled = ([[self.mediaManager sortedImageKeys] count] + [[self.mediaManager sortedVideoKeys] count]) > 0;
    [self.navigationItem.rightBarButtonItem setEnabled:rightBarButtonItemEnabled];
}

- (void) checkIfShouldReturnToTapScreen {
    if (![[self.mediaManager sortedImageKeys] count] && ![[self.mediaManager sortedVideoKeys] count]) {
        [self.navigationController popToViewController:self animated:YES];
    }
}

#pragma mark video extraction

// return YES if no video exists for this time
// but can still fail because of AVMutableComposition failure
// completion block not called if returns NO
- (BOOL)extractVideoForTimeRange:(CMTimeRange)timeRange completion:(void(^)(BOOL success))completion {
    
    NSValue *wrappedTimeRange = [NSValue valueWithCMTimeRange:timeRange];
    if ([[self.mediaManager sortedVideoKeys] containsObject:wrappedTimeRange]) {
        return NO;
    }
    
    // make asset
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSError *error;
    [composition insertTimeRange:timeRange ofAsset:self.player.currentItem.asset atTime:kCMTimeZero error:&error];

    if (!error) {
        // add to media manager
        [self.mediaManager addVideo:composition forKey:wrappedTimeRange completion:^(id key, AVAsset *video) {
            if (completion) {
                completion (YES);
            }
        }];
    
    
    } else {
        // yes we're already on the main queue, but make the call asynchronous so the method returns
        // before the completion block is called
        dispatch_async(dispatch_get_main_queue(), ^{
            completion (NO);
        });
    }
    
    return YES;
}

#pragma mark image extraction

// return YES if no image exists for this time
// but can still fail because of AVAssetImageGenerator failure
// completion block not called if returns NO
- (BOOL)extractImageAtTime:(CMTime)time completion:(void(^)(BOOL success))completion {

    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    if ([[self.mediaManager sortedImageKeys] containsObject:wrappedTime]) {
        return NO;
    }
    
    __weak typeof (self) weakSelf = self;
    NSArray *times =  @[wrappedTime];
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef cgimg, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        
        if (AVAssetImageGeneratorSucceeded == result) {
            assert (!error);
            assert (cgimg);
            UIImage *image = [UIImage imageWithCGImage:cgimg];
            assert (image);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                assert (CMTIME_COMPARE_INLINE(time, ==, requestedTime));
                [weakSelf.mediaManager addImage:image forKey:[NSValue valueWithCMTime:time] completion:^(id key, UIImage *image) {
                    if (completion) {
                        completion (YES);
                    }
                }];
            });
            
        } else if (completion) {
            // yes we're already on the main queue, but make the call asynchronous so the method returns
            // before the completion block is called
            dispatch_async(dispatch_get_main_queue(), ^{
                completion (NO);
            });
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
    [self.playbackBarView setNumberOfPreviewImages:NumberOfPreviewImages];
    [self.playbackBarView setVideoDuration:CMTimeMakeWithSeconds([self.videoAsset duration], 30)];
    
    [self.previewImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef cgimg, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        
        // even if the generation was unsuccessful, add a UIImage as a placeholder
        UIImage *image = [UIImage imageWithCGImage:cgimg];
        NSValue *wrappedTime = [NSValue valueWithCMTime:requestedTime];
        NSUInteger idx = [times indexOfObject:wrappedTime];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.playbackBarView setPreviewImage:image atIndex:idx];
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
    CGSize size = self.playbackBarView.bounds.size;
    
    // don't restrict the width because images are frequently wider than they are tall
    // and we use UIViewContentModeScaleAspectFill
    
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
            [weakSelf.playbackBarView setCurrentTime:time];
        }];
    }
    
    else {
        assert ([self periodicTimeObserver]);
        [self.player removeTimeObserver:[self periodicTimeObserver]];
        self.periodicTimeObserver = nil;
    }
}

- (CMTime) timePerFrame {
    AVAsset *asset = [self.videoAsset asset];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CMTime timePerFrame = CMTimeMake(1,[track nominalFrameRate]);
    return timePerFrame;
}

- (AVPlayer *)player {
    if (![self.playerView player]) {
        [self.playerView setPlayer:[AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:[self.videoAsset asset]]]];
    }
    return [self.playerView player];
}

#pragma mark PlayerViewDelegate methods

- (void)playerView:(PlayerView *)playerView didStartVideoSelection:(CMTimeRange)startTimeRange {
    [self.playbackBarView addVideoIndicatorForTimeRange:startTimeRange];
}

- (void)playerView:(PlayerView *)playerView didUpdateVideoSelection:(CMTimeRange)updatedTimeRange oldTimeRange:(CMTimeRange)oldTimeRange finished:(BOOL)finished {
    
    [self.playbackBarView changeVideoIndicatorForTimeRange:oldTimeRange toTimeRange:updatedTimeRange];

    if (finished) {
        [self extractVideoForTimeRange:updatedTimeRange completion:^(BOOL success) {
            if (!success) {
                [self.playbackBarView removeVideoIndicatorForTimeRange:updatedTimeRange];
            }
        }];
    }
}

- (void)playerView:(PlayerView *)playerView didCancelVideoSelection:(CMTimeRange)timeRange {
    [self.playbackBarView removeVideoIndicatorForTimeRange:timeRange];
}

- (void)playerView:(PlayerView *)playerView didSelectImageAtTime:(CMTime)time {
    [self.playbackBarView addImageIndicatorForTime:time];
    [self extractImageAtTime:time completion:^(BOOL success) {
        if (!success) {
            [self.playbackBarView removeImageIndicatorForTime:time];
        }
    }];
}

- (void)videosChanged:(id)key changeType:(MediaManagerContentChangeType)changeType {
   
    if (MediaManagerContentChangeAdd == changeType) {
        
        if (![[self.playbackBarView videoIndicatorTimeRanges] containsObject:key]) {
            [self.playbackBarView addVideoIndicatorForTimeRange:[key CMTimeRangeValue]];
            assert (NO);
        }
        
    } else if (MediaManagerContentChangeRemove == changeType) {
        [self.playbackBarView removeVideoIndicatorForTimeRange:[key CMTimeRangeValue]];
        
    } else assert (NO);
}

- (void)imagesChanged:(id)key changeType:(MediaManagerContentChangeType)changeType {

    if (MediaManagerContentChangeAdd == changeType) {
        
        if (![[self.playbackBarView imageIndicatorTimes] containsObject:key]) {
            [self.playbackBarView addImageIndicatorForTime:[key CMTimeValue]];
            assert (NO);
        }
        
    } else if (MediaManagerContentChangeRemove == changeType) {
        [self.playbackBarView removeImageIndicatorForTime:[key CMTimeValue]];
        
    } else assert (NO);
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
        
        
        if ([MediaManagerContentTypeVideo isEqualToString:contentType]) {
            [self videosChanged:key changeType:changeType];
        } else if ([MediaManagerContentTypeImage isEqualToString:contentType]) {
            [self imagesChanged:key changeType:changeType];
        } else {
            assert (NO);
        }
        
        
        // housekeeping
        [self checkIfShouldReturnToTapScreen];
        [self updateNextButtonVisibility];
        
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