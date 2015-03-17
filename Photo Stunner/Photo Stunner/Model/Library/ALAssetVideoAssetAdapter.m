//
//  ALAssetVideoAssetAdapter.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "ALAssetVideoAssetAdapter.h"

@interface ALAssetVideoAssetAdapter ()

@property ALAsset *asset;

@end

@implementation ALAssetVideoAssetAdapter {
    UIImage *_thumbnail;
}

- (id)initWithAsset:(ALAsset *)asset {
    self = [super init];
    if (self) {
        self.asset = asset;
    }
    return self;
}

- (UIImage *)thumbnail {
    if (!_thumbnail) {
        
        CGImageRef cgImg = [self.asset aspectRatioThumbnail];
        assert (cgImg);
        
        _thumbnail = [UIImage imageWithCGImage:cgImg];
        assert (_thumbnail);
        
    }
    return _thumbnail;
}

- (CGFloat)duration {
    NSNumber *duration = [self.asset valueForProperty:ALAssetPropertyDuration];
    assert (duration);
    
    return [duration doubleValue];
}

- (NSURL *)contentURL {
    NSURL *contentURL = [self.asset valueForKey:ALAssetPropertyAssetURL];
    assert (contentURL);
    
    return contentURL;
}

@end
