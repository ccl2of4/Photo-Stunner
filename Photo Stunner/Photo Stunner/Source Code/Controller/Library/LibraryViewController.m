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
#import "PhotoStunnerConstants.h"

@interface LibraryViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) NSArray *videos;

@end

@implementation LibraryViewController

static NSString * const CellReuseIdentifier = @"cell";

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"LibraryViewController title", nil);
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"UICollectionViewImageCell" bundle:nil] forCellWithReuseIdentifier:CellReuseIdentifier];
    self.navigationController.navigationBar.translucent = NO;

//    self.automaticallyAdjustsScrollViewInsets = YES;
    
    [self reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:VideoLoaderModelChangedNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat width = (MIN(self.view.frame.size.width,self.view.frame.size.height))/3;
    return CGSizeMake(width, width);
}

#pragma mark notification handling

- (void) handleNotification:(NSNotification *)notification {
    assert ([notification name] == VideoLoaderModelChangedNotification);
    [self reloadData];
}

@end
