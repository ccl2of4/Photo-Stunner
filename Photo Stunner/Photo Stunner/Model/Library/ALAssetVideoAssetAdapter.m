//
//  ALAssetVideoAssetAdapter.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "ALAssetVideoAssetAdapter.h"

@interface ALAssetVideoAssetAdapter ()

@property (nonatomic) ALAsset *backingAsset;

@end

@implementation ALAssetVideoAssetAdapter {
    UIImage *_thumbnail;
}

- (id)initWithAsset:(ALAsset *)asset {
    self = [super init];
    if (self) {
        self.backingAsset = asset;
    }
    return self;
}

- (UIImage *)thumbnail {
    if (!_thumbnail) {
        
        CGImageRef cgImg = [self.backingAsset aspectRatioThumbnail];
        assert (cgImg);
        
        _thumbnail = [UIImage imageWithCGImage:cgImg];
        assert (_thumbnail);
        
    }
    return _thumbnail;
}

- (CGFloat)duration {
    NSNumber *duration = [self.backingAsset valueForProperty:ALAssetPropertyDuration];
    assert (duration);
    
    return [duration doubleValue];
}

- (AVAsset *)asset {
    NSURL *assetURL = [self.backingAsset valueForProperty:ALAssetPropertyAssetURL];
    assert (assetURL);
    
    return [AVAsset assetWithURL:assetURL];
}


@end
