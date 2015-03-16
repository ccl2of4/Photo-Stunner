//
//  LibraryViewController.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "LibraryViewController.h"
#import "UICollectionViewImageCell.h"
#import "TapViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface LibraryViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) NSArray *assets;

@end

@implementation LibraryViewController

static NSString * const CellReuseIdentifier = @"cell";

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewImageCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
    
    [self reloadData];
}

- (void) reloadData {
    NSMutableArray *allAssets = [NSMutableArray new];
    [self enumerateGroupsWithCompletion:^(NSArray *groups) {
        for (ALAssetsGroup *group in groups) {
            [self enumerateAssets:group completion:^(NSArray *assets) {
                [allAssets addObjectsFromArray:assets];
                self.assets = allAssets;
                [self.collectionView reloadData];
            }];
        }
    }];
}

- (void) enumerateAssets:(ALAssetsGroup *)group completion:(void(^)(NSArray *assets))completion {
    NSMutableArray *result = [NSMutableArray new];
    [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (result) {
            [result addObject:asset];
        } else {
            completion (result);
        }
    }];
}

- (void) enumerateGroupsWithCompletion:(void(^)(NSArray *groups))completion {
    NSMutableArray *result = [NSMutableArray new];
    ALAssetsLibrary *lib = [ALAssetsLibrary new];
    
    [lib enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            [result addObject:group];
        } else {
            completion (result);
        }
    } failureBlock:^(NSError *error) {
        assert (NO);
    }];
}

#pragma mark UICollectionViewDelegete/UICollectionViewDataSource methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    ALAsset *asset = self.assets[indexPath.item];
    UIImage *image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
    
    assert (asset);
    assert (image);
    
    [cell.imageView setImage:image];
    
    return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return !![self assets];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.assets count];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset *asset = self.assets[indexPath.item];
    NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
    
    assert (asset);
    assert (url);
    
    TapViewController *tapViewController = [TapViewController new];
    [tapViewController setAssetURL:url];
    
    assert ([self navigationController]);
    [self.navigationController pushViewController:tapViewController animated:YES];

    return;
}

@end
