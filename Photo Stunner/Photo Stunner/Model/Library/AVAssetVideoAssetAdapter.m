//
//  AVAssetVideoAssetAdapter.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "AVAssetVideoAssetAdapter.h"

@interface AVAssetVideoAssetAdapter ()

@property (nonatomic) AVAsset *backingAsset;

@end

@implementation AVAssetVideoAssetAdapter {
    UIImage *_thumbnail;
}

- (id)initWithAsset:(AVAsset *)asset {
    self = [super init];
    if (self) {
        self.backingAsset = asset;
        assert ([self asset]);
        assert ([[self asset] isPlayable]);
    }
    return self;
}

- (UIImage *)thumbnail {
    if (!_thumbnail) {
        
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:[self asset]];
        NSError *error;
        CGImageRef cgImg = [generator copyCGImageAtTime:kCMTimeZero actualTime:nil error:&error];

        assert (!error);
        assert (cgImg);
        
        _thumbnail = [UIImage imageWithCGImage:cgImg];
        CGImageRelease(cgImg);
    }
    
    assert (_thumbnail);
    return _thumbnail;
}

- (CGFloat)duration {
    return CMTimeGetSeconds ([self.asset duration]);
}

- (AVAsset *)asset {
    return [self backingAsset];
}

@end
