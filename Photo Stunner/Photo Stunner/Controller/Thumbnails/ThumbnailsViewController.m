//
//  ThumbnailsViewController.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "ThumbnailsViewController.h"
#import "ImageManager.h"
#import "UICollectionViewImageCell.h"

#import <AVFoundation/AVFoundation.h>

@interface ThumbnailsViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

static NSString * const CellReuseIdentifier = @"cell";

@implementation ThumbnailsViewController

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewImageCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
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
    UIImage *image = [[ImageManager sharedManager] imageForTime:time];
    
    [cell.imageView setImage:image];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return !![[ImageManager sharedManager] sortedTimes];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[[ImageManager sharedManager] sortedTimes] count];
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

@end