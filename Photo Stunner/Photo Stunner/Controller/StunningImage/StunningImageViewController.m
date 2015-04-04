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

@interface StunningImageViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

static NSString * const ImageCellReuseIdentifier = @"image cell";
static NSString * const VideoCellReuseIdentifier = @"video cell";

@implementation StunningImageViewController

static NSString * const VideoSection = @"video section";
static NSString * const ImageSection = @"image section";

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setEdgesForExtendedLayout:UIRectEdgeNone];
        
    [self.collectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:ImageCellReuseIdentifier];
    [self.collectionView registerClass:[UICollectionViewVideoCell class] forCellWithReuseIdentifier:VideoCellReuseIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:MediaManagerContentChangedNotification object:self.mediaManager];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.view layoutIfNeeded];
    
    [self.collectionView scrollToItemAtIndexPath:[self activeIndexPath] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
}

- (void)dealloc {
    [self.collectionView setDelegate:nil];
    [self.collectionView setDataSource:nil];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionInfo = [[self class] sectionInfo];
    if (indexPath.section == [sectionInfo indexOfObject:VideoSection]) {
        UICollectionViewVideoCell *videoCell = (UICollectionViewVideoCell *)cell;
        assert ([videoCell player]);
        [videoCell.player seekToTime:kCMTimeZero];
        [videoCell.player play];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionInfo = [[self class] sectionInfo];
    if (indexPath.section == [sectionInfo indexOfObject:VideoSection]) {
        UICollectionViewVideoCell *videoCell = (UICollectionViewVideoCell *)cell;
        assert ([videoCell player]);
        [videoCell.player pause];
    }
}

-  (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionInfo = [[self class] sectionInfo];
    
    // video
    if (indexPath.section == [sectionInfo indexOfObject:VideoSection]) {
        UICollectionViewVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VideoCellReuseIdentifier forIndexPath:indexPath];
        
        id timeRange = [self.mediaManager sortedVideoKeys][indexPath.item];
        
        [self.mediaManager retrieveVideoForKey:timeRange completion:^(id key, AVAsset *video) {
            AVPlayer *player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:video]];
            [cell setPlayer:player];
            [player play];
        }];
        return cell;
        
    // image
    } else if (indexPath.section == [sectionInfo indexOfObject:ImageSection]){
        UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ImageCellReuseIdentifier forIndexPath:indexPath];
        
        id time = [self.mediaManager sortedImageKeys][indexPath.item];
        
        [self.mediaManager retrieveImageForKey:time completion:^(id key, UIImage *image) {
            assert (image);
            [cell.imageView setImage:image];
        }];
        return cell;
        
    }
    assert (NO);
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

#pragma mark notification handling

- (void) handleNotification:(NSNotification *)notification {
    
    if ([notification name] == MediaManagerContentChangedNotification) {
        assert ([notification object] == [self mediaManager]);
        NSDictionary *userInfo = [notification userInfo];
        
        id key = userInfo[MediaManagerContentKey]; assert (key);
        NSString *contentType = userInfo[MediaManagerContentTypeKey]; assert (contentType);
        NSNumber *changeTypeNum = userInfo[MediaManagerContentChangeTypeKey]; assert (changeTypeNum);
        
        MediaManagerContentChangeType changeType = [changeTypeNum unsignedIntValue];
        
        // video
        if ([MediaManagerContentTypeVideo isEqualToString:contentType]) {
            
            NSUInteger section = [[[self class] sectionInfo] indexOfObject:VideoSection];
            
            // added
            if (MediaManagerContentChangeAdd == changeType) {
                int changedIndex = [self.mediaManager indexOfAddedVideoKey:key];
                NSIndexPath *addedIndexPath = [NSIndexPath indexPathForItem:changedIndex inSection:section];
                [self.collectionView insertItemsAtIndexPaths:@[addedIndexPath]];
                
                // removed
            } else if (MediaManagerContentChangeRemove == changeType) {
                int changedIndex = [self.mediaManager indexOfRemovedVideoKey:key];
                NSIndexPath *removedIndexPath = [NSIndexPath indexPathForItem:changedIndex inSection:section];
                [self.collectionView deleteItemsAtIndexPaths:@[removedIndexPath]];
                
            } else {
                assert (NO);
            }
        }
        
        // image
        else if ([MediaManagerContentTypeImage isEqualToString:contentType]) {
            
            NSUInteger section = [[[self class] sectionInfo] indexOfObject:ImageSection];
            
            // added
            if (MediaManagerContentChangeAdd == changeType) {
                int changedIndex = [self.mediaManager indexOfAddedImageKey:key];
                NSIndexPath *addedIndexPath = [NSIndexPath indexPathForItem:changedIndex inSection:section];
                [self.collectionView insertItemsAtIndexPaths:@[addedIndexPath]];
                
                // removed
            } else if (MediaManagerContentChangeRemove == changeType) {
                int changedIndex = [self.mediaManager indexOfRemovedImageKey:key];
                NSIndexPath *removedIndexPath = [NSIndexPath indexPathForItem:changedIndex inSection:section];
                [self.collectionView deleteItemsAtIndexPaths:@[removedIndexPath]];
                
            } else {
                assert (NO);
            }
            
        } else {
            assert (NO);
        }
        
    } else {
        assert (NO);
    }
}

@end
