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
    // Do any additional setup after loading the view from its nib.
    [self.collectionView registerClass:[UICollectionViewImageCell class] forCellWithReuseIdentifier:CellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ImageManagerSortedTimesChangedNotification object:nil];

}


-  (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    CMTime time = [[[[ImageManager sharedManager] sortedTimes] objectAtIndex:0] CMTimeValue];
    cell.imageView.image = [[ImageManager sharedManager] imageForTime:time];

    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[[ImageManager sharedManager] sortedTimes] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return !!self.collectionView;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout   sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CGSize size = self.collectionView.frame.size;
    assert(!CGSizeEqualToSize(size, CGSizeZero));
    return size;
}


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
            [self.collectionView insertItemsAtIndexPaths:@[removedIndexPath]];
            
        } else {
            assert (NO);
        }
        
    } else {
        assert (NO);
    }
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end