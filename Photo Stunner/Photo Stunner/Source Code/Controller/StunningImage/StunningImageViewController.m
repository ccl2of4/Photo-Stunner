//
//  StunningImageViewController.m
//  Photo Stunner
//
//  Created by Ryan Brooks on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "StunningImageViewController.h"
#import "MediaManager.h"
#import "MediaManager+CMTimeImageKeys.h"
#import "MediaManager+CMTimeRangeVideoKeys.h"
#import "UICollectionViewImageCell.h"
#import "UICollectionViewVideoCell.h"
#import <AVFoundation/AVFoundation.h>
#import "Photo_Stunner-Swift.h"

@interface StunningImageViewController () <UICollectionViewDataSource, UICollectionViewDelegate, MediaManagerObserverDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) MediaManagerObserver *mediaManagerObserver;

@end

static NSString * const ImageCellReuseIdentifier = @"image cell";
static NSString * const VideoCellReuseIdentifier = @"video cell";

@implementation StunningImageViewController

static NSString * const VideoSection = @"video section";
static NSString * const ImageSection = @"image section";

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setEdgesForExtendedLayout:UIRectEdgeNone];
        
    [self.collectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:ImageCellReuseIdentifier];
    [self.collectionView registerClass:[UICollectionViewVideoCell class] forCellWithReuseIdentifier:VideoCellReuseIdentifier];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.view layoutIfNeeded];
    [self.collectionView scrollToItemAtIndexPath:[self activeIndexPath] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
}

- (void)dealloc {
    [self.collectionView setDelegate:nil];
    [self.collectionView setDataSource:nil];
}

- (void)setMediaManager:(MediaManager *)mediaManager {
    self.mediaManagerObserver = [[MediaManagerObserver alloc] initWithMediaManager:mediaManager];
    self.mediaManagerObserver.delegate = self;
    
    _mediaManager = mediaManager;
}

#pragma mark UICollectionViewDelegate/UICollectionViewDataSource methods

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionInfo = [[self class] sectionInfo];
    if (indexPath.section == [sectionInfo indexOfObject:VideoSection]) {
        UICollectionViewVideoCell *videoCell = (UICollectionViewVideoCell *)cell;

        // this is needed in case the video is cached
        // the conditional in the creation method will return false in that case
        // since the cell is not visible until after it is finished being created
        [videoCell.player seekToTime:kCMTimeZero];
        [videoCell.player play];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionInfo = [[self class] sectionInfo];
    if (indexPath.section == [sectionInfo indexOfObject:VideoSection]) {
        UICollectionViewVideoCell *videoCell = (UICollectionViewVideoCell *)cell;
        
        // even if the player wasn't created in time, it won't matter if it's nil here
        // because it wouldn't have started playing anyway
        [videoCell.player pause];
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView videoCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VideoCellReuseIdentifier forIndexPath:indexPath];
    
    id timeRange = [self.mediaManager sortedVideoKeys][indexPath.item];
    
    [self.mediaManager retrieveVideoForKey:timeRange completion:^(id key, AVAsset *video) {
        AVPlayer *player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:video]];
        [cell setPlayer:player];
        
        // only play if the user is still looking at this cell
        if ([[self.collectionView indexPathsForVisibleItems] containsObject:indexPath]) {
            [player play];
        }
        
    }];
    return cell;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView imageCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ImageCellReuseIdentifier forIndexPath:indexPath];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    id time = [self.mediaManager sortedImageKeys][indexPath.item];
    
    [self.mediaManager retrieveImageForKey:time completion:^(id key, UIImage *image) {
        assert (image);
        [cell.imageView setImage:image];
    }];
    return cell;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionInfo = [[self class] sectionInfo];
    
    if ([sectionInfo indexOfObject:VideoSection] == indexPath.section) {
        return [self collectionView:collectionView videoCellForItemAtIndexPath:indexPath];
        
    } else if ([sectionInfo indexOfObject:ImageSection] == indexPath.section){
        return [self collectionView:collectionView imageCellForItemAtIndexPath:indexPath];
    }
    
    assert (NO);
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray *sectionInfo = [[self class] sectionInfo];
    if (section == [sectionInfo indexOfObject:VideoSection]) {
        return [[self.mediaManager sortedVideoKeys] count];
    } else if (section == [sectionInfo indexOfObject:ImageSection]) {
        return [[self.mediaManager sortedImageKeys] count];
    } else assert (NO);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return [[[self class] sectionInfo] count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CGSize size = self.collectionView.frame.size;
    assert(!CGSizeEqualToSize(size, CGSizeZero));
    return size;
}

+ (NSArray *)sectionInfo {
    static NSArray *sectionInfo;
    if (!sectionInfo) {
        sectionInfo = @[VideoSection,ImageSection];
    }
    return sectionInfo;
}

#pragma mark MediaManagerObserverDelegate methods

- (void)mediaManagerAddedVideo:(id)key {
    NSUInteger section = [self indexPathForVideoKey:key];
    NSUInteger changedIndex = [self.mediaManager indexOfAddedVideoKey:key];
    NSIndexPath *addedIndexPath = [NSIndexPath indexPathForItem:changedIndex inSection:section];
    [self.collectionView insertItemsAtIndexPaths:@[addedIndexPath]];
}

- (void)mediaManagerRemovedVideo:(id)key {
    NSUInteger section = [self indexPathForVideoKey:key];
    NSUInteger changedIndex = [self.mediaManager indexOfRemovedVideoKey:key];
    NSIndexPath *removedIndexPath = [NSIndexPath indexPathForItem:changedIndex inSection:section];
    [self.collectionView deleteItemsAtIndexPaths:@[removedIndexPath]];
}

- (void)mediaManagerAddedImage:(id)key {
    NSUInteger section = [self indexPathForImageKey:key];
    NSUInteger changedIndex = [self.mediaManager indexOfAddedImageKey:key];
    NSIndexPath *addedIndexPath = [NSIndexPath indexPathForItem:changedIndex inSection:section];
    [self.collectionView insertItemsAtIndexPaths:@[addedIndexPath]];
}

- (void)mediaManagerRemovedImage:(id)key {
    NSUInteger section = [self indexPathForImageKey:key];
    NSUInteger changedIndex = [self.mediaManager indexOfRemovedImageKey:key];
    NSIndexPath *removedIndexPath = [NSIndexPath indexPathForItem:changedIndex inSection:section];
    [self.collectionView deleteItemsAtIndexPaths:@[removedIndexPath]];
}

- (NSUInteger)indexPathForVideoKey:(id)key {
    return [[[self class] sectionInfo] indexOfObject:VideoSection];
}

- (NSUInteger)indexPathForImageKey:(id)key {
    return [[[self class] sectionInfo] indexOfObject:ImageSection];
}

@end
