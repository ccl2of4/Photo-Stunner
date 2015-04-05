//
//  VideoAsset.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol VideoAsset <NSObject>

- (AVAsset *) asset;
- (UIImage *) thumbnail;
- (CGFloat) duration;

@end
