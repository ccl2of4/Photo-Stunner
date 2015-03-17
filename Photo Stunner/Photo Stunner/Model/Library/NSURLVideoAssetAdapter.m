//
//  AVAssetVideoAssetAdapter.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "NSURLVideoAssetAdapter.h"

@interface NSURLVideoAssetAdapter ()

@property AVURLAsset *asset;
@property NSURL *url;

@end

@implementation NSURLVideoAssetAdapter {
    UIImage *_thumbnail;
}

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        self.url = url;
        self.asset = [AVURLAsset URLAssetWithURL:url options:nil];
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

- (NSURL *)contentURL {
    NSURL *contentURL = [self.asset URL];
    assert (contentURL);
    
    return contentURL;
}

@end
