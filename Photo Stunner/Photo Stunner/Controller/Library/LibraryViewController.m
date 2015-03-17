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
#import "VideoLoader.h"

@interface LibraryViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) NSArray *videos;

@end

@implementation LibraryViewController

static NSString * const CellReuseIdentifier = @"cell";

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:CellReuseIdentifier];
    
    [self reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:VideoLoaderModelChangedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark logic

- (void) reloadData {
    [[VideoLoader sharedInstance] loadVideos:^(NSArray *videos) {
        self.videos = videos;
        [self.collectionView reloadData];
    }];
}

#pragma mark UICollectionViewDelegete/UICollectionViewDataSource methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    id<VideoAsset> asset = self.videos[indexPath.item];
    UIImage *image = [asset thumbnail];
    
    assert (asset);
    assert (image);
    
    [cell.imageView setImage:image];
    
    return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return !![self videos];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.videos count];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id<VideoAsset> asset = self.videos[indexPath.item];
    assert (asset);
    
    TapViewController *tapViewController = [TapViewController new];
    [tapViewController setVideoAsset:asset];
    
    assert ([self navigationController]);
    [self.navigationController pushViewController:tapViewController animated:YES];
}

#pragma mark notification handling

- (void) handleNotification:(NSNotification *)notification {
    assert ([notification name] == VideoLoaderModelChangedNotification);
    [self reloadData];
}

@end
