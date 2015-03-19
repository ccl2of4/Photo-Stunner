//
//  StunningImageViewController.m
//  Photo Stunner
//
//  Created by Ryan Brooks on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "StunningImageViewController.h"
#import "ImageManager.h"
#import "UICollectionViewImageCell.h"
#import <AVFoundation/AVFoundation.h>

@interface StunningImageViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

static NSString * const CellIdentifier = @"cell";

@implementation StunningImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:CellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ImageManagerSortedTimesChangedNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [self.view layoutIfNeeded];
    
    assert ([self.collectionView numberOfSections] == 1);
    assert ([self.collectionView numberOfItemsInSection:0] > [self imageIndex]);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self imageIndex] inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
}

-  (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ImageManager *imageManager = [ImageManager sharedManager];
    
    CMTime time = [[imageManager sortedTimes][indexPath.item] CMTimeValue];
    
    [imageManager retrieveImageForTime:time completion:^(CMTime time, UIImage *image) {
        assert (image);
        if ([[collectionView indexPathForCell:cell] isEqual:indexPath]) {
            [cell.imageView setImage:image];
        }
    }];

    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[[ImageManager sharedManager] sortedTimes] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return !!self.collectionView;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CGSize size = self.collectionView.frame.size;
    assert(!CGSizeEqualToSize(size, CGSizeZero));
    return size;
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
