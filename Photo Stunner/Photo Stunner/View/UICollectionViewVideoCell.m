//
//  CollectionViewVideoCell.m
//  Photo Stunner
//
//  Created by Connor Lirot on 4/1/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "UICollectionViewVideoCell.h"

@interface UICollectionViewVideoCell ()

@property AVPlayerLayer *playerLayer;

@end

@implementation UICollectionViewVideoCell

- (void)setPlayer:(AVPlayer *)player {
    [self.contentView setFrame:[self bounds]];
    
    [self.playerLayer removeFromSuperlayer];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [self.playerLayer setFrame:[self.contentView bounds]];
    [self.contentView.layer addSublayer:self.playerLayer];
    
    _player = player;
}

@end
