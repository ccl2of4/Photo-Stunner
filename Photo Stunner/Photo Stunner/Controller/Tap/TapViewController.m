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

@property (nonatomic) AVAssetImageGenerator *imageGenerator;
@property (nonatomic) AVAssetImageGenerator *previewImageGenerator;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) NSMutableArray *previewImages;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ImageManagerSortedTimesChangedNotification object:nil];
    
    [self.previewBarCollectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:CellReuseIdentifier];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (![self previewImages]) {
        [self generatePreviewImages];
    }
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.player play];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UI events

- (IBAction)handleUIGestureRecognizerRecognized:(id)sender {
    if ([sender isKindOfClass:[UITapGestureRecognizer class]] && [sender view] == self.playbackView) {
        [self extractAndSaveImageAtCurrentTime];
    } else {
        assert (NO);
    }
}

- (void)handleUIControlEventTouchUpInside:(id)sender{
    assert(self.navigationController);

    ThumbnailsViewController *thumbnailsViewController = [ThumbnailsViewController new];
    [self.navigationController pushViewController:thumbnailsViewController animated:YES];
}

#pragma mark logic

- (void)extractAndSaveImageAtCurrentTime {
    [self extractImageAtTime:[self.player currentTime] completion:^(CMTime time, CGImageRef result) {
        
        assert (result);
        UIImage *image = [UIImage imageWithCGImage:result];
        assert (image);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ImageManager sharedManager] addImage:image forTime:time];
        });
    }];
}

- (void)extractImageAtTime:(CMTime)time completion:(void(^)(CMTime time, CGImageRef result))completion {
    NSArray *times = @[[NSValue valueWithCMTime:time]];
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if ( result == AVAssetImageGeneratorSucceeded ) {
            assert (image);
            completion (requestedTime, image);
        } else {
            completion (requestedTime, nil);
        }
    }];
}

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

- (AVAssetImageGenerator *)imageGenerator {
    if (!_imageGenerator) {
        AVAsset *asset = [self.videoAsset asset];
        _imageGenerator= [[AVAssetImageGenerator alloc] initWithAsset:asset];
        [_imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
        [_imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    }
    return _imageGenerator;
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

#pragma mark notification handling

- (void)handleNotification:(NSNotification *)notification {
    if ([notification name] == ImageManagerSortedTimesChangedNotification) {
        BOOL rightBarButtonItemEnabled = [[[ImageManager sharedManager] sortedTimes] count] > 0;
        [self.navigationItem.rightBarButtonItem setEnabled:rightBarButtonItemEnabled];
    } else {
        assert (NO);
    }
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

@end
