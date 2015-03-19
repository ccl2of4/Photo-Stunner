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
#import "UICollectionViewImageCell.h"
#import <AVFoundation/AVFoundation.h>

@interface TapViewController () <UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *playbackView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UICollectionView *previewBarCollectionView;
@property (nonatomic) UIView *playbackTrackerView;

@property (nonatomic) AVAssetImageGenerator *imageGenerator;
@property (nonatomic) AVAssetImageGenerator *previewImageGenerator;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) NSMutableArray *previewImages;
@property (nonatomic) NSMutableArray *tapIndicatorViews;
@property (nonatomic) id periodicTimeObserver;

@end

@implementation TapViewController

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
    [self setPeriodicTimeObserverEnabled:YES];
    [self.player play];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    [self setPeriodicTimeObserverEnabled:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UI events

- (IBAction)handleUIGestureRecognizerRecognized:(id)sender {
    if ([sender isKindOfClass:[UITapGestureRecognizer class]] && [sender view] == self.playbackView) {
        [self tap];
    } else {
        assert (NO);
    }
}

- (void)handleUIControlEventTouchUpInside:(id)sender{
    assert(self.navigationController);

    ThumbnailsViewController *thumbnailsViewController = [ThumbnailsViewController new];
    [self.navigationController pushViewController:thumbnailsViewController animated:YES];
}

#pragma mark image generation

- (void) tap {
    CMTime time = [self.player currentTime];
    NSValue *wrappedTime = [NSValue valueWithCMTime:time];
    NSArray *times = @[wrappedTime];
    
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef cgimg, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if ( result == AVAssetImageGeneratorSucceeded ) {
            assert (cgimg);
            UIImage *image = [UIImage imageWithCGImage:cgimg];
            assert (image);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                assert (CMTIME_COMPARE_INLINE(time, ==, requestedTime));
                [[ImageManager sharedManager] addImage:image forTime:time];
            });
            
        } else {
        }
    }];
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
        if (result == AVAssetImageGeneratorSucceeded) {
            assert (cgimg);
            UIImage *image = [UIImage imageWithCGImage:cgimg];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.previewImages addObject:image];
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.previewImages indexOfObject:image] inSection:0];
                [self.previewBarCollectionView insertItemsAtIndexPaths:@[indexPath]];
            });
        }
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
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        
        [player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        
        [self.playbackView.layer addSublayer:playerLayer];
        [playerLayer setFrame:[self.playbackView.layer bounds]];
        
        _player = player;
    }
    
    return _player;
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

#pragma mark notification handling

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


@end