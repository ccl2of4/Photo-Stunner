//
//  ThumbnailsViewController.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "ThumbnailsViewController.h"
#import "ImageManager.h"
#import "StunningImageViewController.h"
#import "UICollectionViewImageCell.h"

#import <AVFoundation/AVFoundation.h>

@interface ThumbnailsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

static NSString * const CellReuseIdentifier = @"cell";

@implementation ThumbnailsViewController

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:CellReuseIdentifier];
    [self.collectionView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ImageManagerSortedTimesChangedNotification object:nil];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UICollectionViewDelegate/UICollectionViewDataSource methods

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    ImageManager *imageManager = [ImageManager sharedManager];
    
    CMTime time = [[imageManager sortedTimes][indexPath.item] CMTimeValue];

    [imageManager retrieveThumbnailImageForTime:time completion:^(CMTime time, UIImage *image) {
        assert (image);
        [cell.imageView setImage:image];
    }];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    assert ([[ImageManager sharedManager] sortedTimes]);
    
    return !![[ImageManager sharedManager] sortedTimes];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    assert ([[ImageManager sharedManager] sortedTimes]);
    assert ([[[ImageManager sharedManager] sortedTimes] count]);
    
    return [[[ImageManager sharedManager] sortedTimes] count];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    NSString *title = [NSString stringWithFormat:@"Image %d", (indexPath.item + 1)];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove" otherButtonTitles:@"View", @"Save", nil];
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [actionSheet setTag:indexPath.item];
    [actionSheet showInView:self.view];

}

#pragma mark UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSUInteger itemNum = [actionSheet tag];
    ImageManager *imageManager = [ImageManager sharedManager];
    NSValue *wrappedTime = [imageManager sortedTimes][itemNum];
    CMTime time = [wrappedTime CMTimeValue];
    
    // delete
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {

        [imageManager removeImageForTime:time];

    // view
    } else if (buttonIndex == [actionSheet firstOtherButtonIndex]) {

        StunningImageViewController *stunningImageViewController = [StunningImageViewController new];
        [stunningImageViewController setImageIndex:itemNum];
        
        assert ([self navigationController]);
        [self.navigationController pushViewController:stunningImageViewController animated:YES];
        
    // save
    } else if (buttonIndex == ([actionSheet firstOtherButtonIndex] + 1)) {
        
        [imageManager retrieveImageForTime:time completion:^(CMTime time, UIImage *image) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
        }];
        
    }
}

#pragma mark notification handling

- (void) handleNotification:(NSNotification *)notification {
    
    if ([notification name] == ImageManagerSortedTimesChangedNotification) {
        NSDictionary *userInfo = [notification userInfo];
        NSNumber *changedIndex;
        
        // added an image
        if ( (changedIndex = [userInfo objectForKey:ImageManagerSortedTimesAddedIndexKey]) ) {
            NSIndexPath *addedIndexPath = [NSIndexPath indexPathForItem:[changedIndex integerValue] inSection:0];
            [self.collectionView insertItemsAtIndexPaths:@[addedIndexPath]];
            
        // removed an image
        } else if ( (changedIndex = [userInfo objectForKey:ImageManagerSortedTimesRemovedIndexKey]) ) {
            NSIndexPath *removedIndexPath = [NSIndexPath indexPathForItem:[changedIndex integerValue] inSection:0];
            [self.collectionView deleteItemsAtIndexPaths:@[removedIndexPath]];
            
        } else {
            assert (NO);
        }
        
    } else {
        assert (NO);
    }
}

@end
