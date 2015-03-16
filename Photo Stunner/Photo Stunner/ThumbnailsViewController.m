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

@property NSArray *sortedTimes;

@end

static NSString * const CellReuseIdentifier = @"cell";

@implementation ThumbnailsViewController

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewImageCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
}

- (void) reloadData {
    self.sortedTimes = [[[ImageManager sharedManager] sortedTimes] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CMTime time1 = [obj1 CMTimeValue];
        CMTime time2 = [obj2 CMTimeValue];
        
        int32_t compare = CMTimeCompare(time1, time2);
        
        return
            compare < 0 ?   NSOrderedAscending  :
            compare > 0 ?   NSOrderedDescending :
                            NSOrderedSame;
    }];
    [self.collectionView reloadData];
}

#pragma mark UICollectionViewDelegate/UICollectionViewDataSource methods

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    CMTime time = [self.sortedTimes[indexPath.item] CMTimeValue];
    UIImage *image = [[ImageManager sharedManager] imageForTime:time];
    
    [cell.imageView setImage:image];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return !![self sortedTimes];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.sortedTimes count];
}

@end
