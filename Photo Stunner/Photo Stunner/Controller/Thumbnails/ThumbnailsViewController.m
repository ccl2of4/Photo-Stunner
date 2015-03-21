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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ImageManagerSortedTimesChangedNotification object:self.imageManager];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.collectionView setDelegate:nil];
    [self.collectionView setDataSource:nil];
}

#pragma mark UICollectionViewDelegate/UICollectionViewDataSource methods

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    CMTime time = [[self.imageManager sortedTimes][indexPath.item] CMTimeValue];

    [self.imageManager retrieveThumbnailImageForTime:time completion:^(CMTime time, UIImage *image) {
        assert (image);
        [cell.imageView setImage:image];
    }];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    assert ([self.imageManager sortedTimes]);
    
    return !![self.imageManager sortedTimes];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    assert ([self.imageManager sortedTimes]);
    
    return [[self.imageManager sortedTimes] count];
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
    NSValue *wrappedTime = [self.imageManager sortedTimes][itemNum];
    CMTime time = [wrappedTime CMTimeValue];
    
    // delete
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {

        [self.imageManager removeImageForTime:time];

    // view
    } else if (buttonIndex == [actionSheet firstOtherButtonIndex]) {

        StunningImageViewController *stunningImageViewController = [StunningImageViewController new];
        [stunningImageViewController setImageManager:[self imageManager]];
        [stunningImageViewController setImageIndex:itemNum];
        
        assert ([self navigationController]);
        [self.navigationController pushViewController:stunningImageViewController animated:YES];
        
    // save
    } else if (buttonIndex == ([actionSheet firstOtherButtonIndex] + 1)) {
        
        [self.imageManager retrieveImageForTime:time completion:^(CMTime time, UIImage *image) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
        }];
        
    }
}

#pragma mark notification handling

- (void) handleNotification:(NSNotification *)notification {
    
    if ([notification name] == ImageManagerSortedTimesChangedNotification) {
        assert ([notification object] == [self imageManager]);
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
