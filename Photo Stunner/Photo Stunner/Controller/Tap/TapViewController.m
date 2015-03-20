//
//  TapViewController.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "TapViewController.h"
#import "ImageManager.h"
#import "ThumbnailsViewController.h"
#import "FlashView.h"
#import "UICollectionViewImageCell.h"
#import <AVFoundation/AVFoundation.h>

@interface TapViewController () <UICollectionViewDelegateFlowLayout,UICollectionViewDataSource, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *playbackView;
@property (weak, nonatomic) IBOutlet UIView *playerLayerView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UICollectionView *previewBarCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *backStepButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardStepButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) FlashView *flashView;
@property (nonatomic) UIView *playbackTrackerView;
@property (nonatomic) AVPlayerLayer *playerLayer;

@property (nonatomic) AVAssetImageGenerator *imageGenerator;
@property (nonatomic) AVAssetImageGenerator *previewImageGenerator;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) NSMutableArray *previewImages;
@property (nonatomic) NSMutableArray *tapIndicatorViews;
@property (nonatomic) id periodicTimeObserver;

@end

@implementation TapViewController

static void * PlayerStatusObservingContext = &PlayerStatusObservingContext;
static void * PlayerRateObservingContext = &PlayerRateObservingContext;
static NSString * const CellReuseIdentifier = @"cell";
static const NSUInteger NumberOfPreviewImages = 10;

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(handleUIControlEventTouchUpInside:)];
    [rightBarButtonItem setEnabled:NO];
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
    
    [self.imageView setImage:[self.videoAsset thumbnail]];
    
    [self.previewBarCollectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:CellReuseIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ImageManagerSortedTimesChangedNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![self previewImages]) {
        [self generatePreviewImages];
    }
    
    [self playbackTrackerView];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.player play];
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
}

#pragma mark UI events

- (IBAction)handleUIGestureRecognizerRecognized:(id)sender {
    
    // tapped video
    if ([sender isKindOfClass:[UITapGestureRecognizer class]] && [sender view] == self.playbackView) {
        
        CMTime time = [self.player currentTime];
        if ([self extractImageAtTime:time]) {
            [self.flashView flash];
        }

    // tapped preview bar
    } else if ([sender isKindOfClass:[UITapGestureRecognizer class]] && [sender view] == self.previewBarCollectionView){
        
        CGPoint location = [sender locationInView:self.previewBarCollectionView];
        CGFloat percent = location.x / self.previewBarCollectionView.bounds.size.width;
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

#pragma mark image generation

- (BOOL) extractImageAtTime:(CMTime)time {
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    ImageManager *imageManager = [ImageManager sharedManager];
    
    if ([[imageManager sortedTimes] containsObject:wrappedTime]) {
        return NO;
    }
    
    NSArray *times = @[wrappedTime];
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef cgimg, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if ( result == AVAssetImageGeneratorSucceeded ) {
            assert (!error);
            assert (cgimg);
            UIImage *image = [UIImage imageWithCGImage:cgimg];
            assert (image);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                assert (CMTIME_COMPARE_INLINE(time, ==, requestedTime));
                [imageManager addImage:image forTime:time];
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

- (void) addTapIndicatorView:(NSUInteger)idx {
    ImageManager *imageManager = [ImageManager sharedManager];
    
    NSValue *wrappedTime = [imageManager sortedTimes][idx];
    assert (wrappedTime);
    
    CMTime time = [wrappedTime CMTimeValue];
    
    UIView *tapIndicatorView = [self createTapIndicatorForTime:time];
    [self.view addSubview:tapIndicatorView];
    
    assert ([self tapIndicatorViews]);
    [self.tapIndicatorViews insertObject:tapIndicatorView atIndex:idx];
}

- (void) removeTapIndicatorView:(NSUInteger)idx {
    UIView *tapIndicatorView = self.tapIndicatorViews[idx];
    [tapIndicatorView removeFromSuperview];
    
    assert([self tapIndicatorViews]);
    [self.tapIndicatorViews removeObjectAtIndex:idx];
}

- (UIView *)createTapIndicatorForTime:(CMTime)time {
    CMTime vidLength = [self.player.currentItem duration];
    Float64 percent = CMTimeGetSeconds(time) / CMTimeGetSeconds(vidLength);
    
    CGRect previewBarCollectionViewFrame = [self.previewBarCollectionView frame];
    CGFloat width = 3.0f;
    CGFloat height = 3.0f;
    CGFloat x = (previewBarCollectionViewFrame.origin.x + percent * previewBarCollectionViewFrame.size.width) - (0.5 * width);
    CGFloat y = CGRectGetMidY(previewBarCollectionViewFrame) - (0.5 * height);
    
    CGRect frame = CGRectMake(x, y, width, height);
    
    UIView *photoIndicatorView = [[UIView alloc] initWithFrame:frame];
    [photoIndicatorView setBackgroundColor:[UIColor whiteColor]];
    
    return photoIndicatorView;
}

-(NSMutableArray *)tapIndicatorViews {
    if (!_tapIndicatorViews) {
        _tapIndicatorViews = [NSMutableArray new];
    }
    return _tapIndicatorViews;
}

#pragma mark preview images

- (void)generatePreviewImages {
    assert (![self previewImages]);
    
    self.previewImages = [NSMutableArray new];
    
    NSArray *times = [self timesForPreviewImages];
    
    [self.previewImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef cgimg, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        
        // even if the generation was unsuccessful, add a UIImage as a placeholder
        UIImage *image = [UIImage imageWithCGImage:cgimg];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.previewImages addObject:image];
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.previewImages indexOfObject:image] inSection:0];
            [self.previewBarCollectionView insertItemsAtIndexPaths:@[indexPath]];
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
    CGSize size = self.previewBarCollectionView.bounds.size;
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
            CGRect previewBarCollectionViewFrame = [weakSelf.previewBarCollectionView frame];
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
        CGRect previewBarCollectionViewFrame = [self.previewBarCollectionView frame];
        CGFloat width = 2.0f;
        CGFloat height = previewBarCollectionViewFrame.size.height;
        CGFloat x = previewBarCollectionViewFrame.origin.x - (0.5 * width);
        CGFloat y = previewBarCollectionViewFrame.origin.y;
        
        CGRect frame = CGRectMake(x, y, width, height);
        
        _playbackTrackerView = [[UIView alloc] initWithFrame:frame];
        [_playbackTrackerView setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:_playbackTrackerView];
    }
    return _playbackTrackerView;
}

- (CMTime) timePerFrame {
    AVAsset *asset = [self.videoAsset asset];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CMTime timePerFrame = CMTimeMake(1,[track nominalFrameRate]);
    return timePerFrame;
}

#pragma mark UICollectionViewDelegate/UICollectionViewDataSouce methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    UIImage *image = self.previewImages[indexPath.item];
    
    assert (cell);
    assert (image);
    
    [cell.imageView setImage:image];
    
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.previewImages count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = [self maximumSizeForPreviewImages];
    return size;
}



#pragma mark observer methods

- (void)handleNotification:(NSNotification *)notification {
    if ([notification name] == ImageManagerSortedTimesChangedNotification) {
        NSDictionary *userInfo = [notification userInfo];
        NSNumber *changedIndex;
        
        if ( (changedIndex = [userInfo objectForKey:ImageManagerSortedTimesAddedIndexKey]) ) {
            NSUInteger idx = [changedIndex unsignedIntegerValue];
            [self addTapIndicatorView:idx];

        } else if ( (changedIndex = [userInfo objectForKey:ImageManagerSortedTimesRemovedIndexKey]) ) {
            NSUInteger idx = [changedIndex unsignedIntegerValue];
            [self removeTapIndicatorView:idx];
            
        } else {
            assert (NO);
        }
        
        BOOL rightBarButtonItemEnabled = [[[ImageManager sharedManager] sortedTimes] count] > 0;
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