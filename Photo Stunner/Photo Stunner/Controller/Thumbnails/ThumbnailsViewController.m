//
//  ThumbnailsViewController.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "ThumbnailsViewController.h"
#import "MediaManager.h"
#import "MediaManager+CMTimeImageKeys.h"
#import "MediaManager+CMTimeRangeVideoKeys.h"
#import "StunningImageViewController.h"
#import "UICollectionViewImageCell.h"
#import "UICollectionViewHeaderCell.h"

#import <AVFoundation/AVFoundation.h>

@interface ThumbnailsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

static NSString * const CellReuseIdentifier = @"cell";
static NSString * const HeaderReuseIdentifier = @"header";

@implementation ThumbnailsViewController

static NSString * const VideoSection = @"video section";
static NSString * const ImageSection = @"image section";

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"UICollectionViewHeaderCell" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HeaderReuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:CellReuseIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:MediaManagerContentChangedNotification object:self.mediaManager];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.collectionView setDelegate:nil];
    [self.collectionView setDataSource:nil];
}

#pragma mark UICollectionViewDelegate/UICollectionViewDataSource methods

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    NSArray *sectionInfo = [[self class] sectionInfo];
    
    // video
    if (indexPath.section == [sectionInfo indexOfObject:VideoSection]) {
    
        id timeRange = [self.mediaManager sortedVideoKeys][indexPath.item];
        
        [self.mediaManager retrieveVideoThumbnailImageForKey:timeRange completion:^(id key, UIImage *image) {
            assert (image);
            [cell.imageView setImage:image];
        }];
    
    // image
    } else if (indexPath.section == [sectionInfo indexOfObject:ImageSection]){
        
        id time = [self.mediaManager sortedImageKeys][indexPath.item];

        [self.mediaManager retrieveThumbnailImageForKey:time completion:^(id key, UIImage *image) {
            assert (image);
            [cell.imageView setImage:image];
        }];
    
    
    } else assert (NO);
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    assert ([kind isEqualToString:UICollectionElementKindSectionHeader]);
    
    UICollectionViewHeaderCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HeaderReuseIdentifier forIndexPath:indexPath];
    
    NSArray *sectionInfo = [[self class] sectionInfo];
    NSString *title;
    if (indexPath.section == [sectionInfo indexOfObject:VideoSection]) {
        title = NSLocalizedString(@"ThumbnailsViewControllerVideoSectionTitle", nil);
    } else if (indexPath.section == [sectionInfo indexOfObject:ImageSection]) {
        title = NSLocalizedString(@"ThumbnailsViewControllerImageSectionTitle", nil);
    } else assert (NO);
    
    [cell.titleLabel setText:title];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [[[self class] sectionInfo] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *sectionInfo = [[self class] sectionInfo];
    if (section == [sectionInfo indexOfObject:VideoSection]) {
        return [[self.mediaManager sortedVideoKeys] count];
    } else if (section == [sectionInfo indexOfObject:ImageSection]) {
        return [[self.mediaManager sortedImageKeys] count];
    } else assert (NO);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    NSString *title = NSLocalizedString(@"ThumbnailsViewController Title", nil);
    NSString *remove = NSLocalizedString(@"ThumbnailsViewController Remove", @"Remove/Delete selected image");
    NSString *view = NSLocalizedString(@"ThumbnailsViewController View", @"View selected image");
    NSString *save = NSLocalizedString(@"ThumbnailsViewController Save", @"Save selected image");
    
    NSString *fullTitle = [NSString stringWithFormat:@"%@ %d", title, (indexPath.item + 1)];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:fullTitle delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:remove otherButtonTitles:view,save, nil];
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [actionSheet setTag:indexPath.item];
    [actionSheet showInView:self.view];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    
    return CGSizeMake(collectionView.bounds.size.width, 50.0);
}

+ (NSArray *)sectionInfo {
    static NSArray *sectionInfo;
    if (!sectionInfo) {
        sectionInfo = @[VideoSection,ImageSection];
    }
    return sectionInfo;
}

#pragma mark UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
    
    // video
    if (indexPath.section == 0) {
        id key = [self.mediaManager sortedVideoKeys][indexPath.item];
    
        // delete
        if (buttonIndex == [actionSheet destructiveButtonIndex]) {
            [self.mediaManager removeVideoForKey:key];
            
        // view
        } else if (buttonIndex == [actionSheet firstOtherButtonIndex]) {
            
            StunningImageViewController *stunningImageViewController = [StunningImageViewController new];
            [stunningImageViewController setMediaManager:[self mediaManager]];
            [stunningImageViewController setActiveIndexPath:indexPath];
            
            assert ([self navigationController]);
            [self.navigationController pushViewController:stunningImageViewController animated:YES];
            
        // save
        } else if (buttonIndex == ([actionSheet firstOtherButtonIndex] + 1)) {
            [self.mediaManager retrieveVideoForKey:key completion:^(id key, AVAsset *video) {
                NSString *videoPath = [[(AVURLAsset *)video URL] absoluteString]; // probably not the best way to get the URL
                UISaveVideoAtPathToSavedPhotosAlbum(videoPath, nil, nil, nil);
            }];
        }
    
    // image
    } else if (indexPath.section == 1) {
        id key = [self.mediaManager sortedImageKeys][indexPath.item];
    
        // delete
        if (buttonIndex == [actionSheet destructiveButtonIndex]) {
            [self.mediaManager removeImageForKey:key];

        // view
        } else if (buttonIndex == [actionSheet firstOtherButtonIndex]) {

            StunningImageViewController *stunningImageViewController = [StunningImageViewController new];
            [stunningImageViewController setMediaManager:[self mediaManager]];
            [stunningImageViewController setActiveIndexPath:indexPath];
            
            assert ([self navigationController]);
            [self.navigationController pushViewController:stunningImageViewController animated:YES];
            
        // save
        } else if (buttonIndex == ([actionSheet firstOtherButtonIndex] + 1)) {
            [self.mediaManager retrieveImageForKey:key completion:^(id key, UIImage *image) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
            }];
        }
    }
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
