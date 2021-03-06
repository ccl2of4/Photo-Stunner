//
//  AVAssetVideoAssetAdapter.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoAsset.h"

@interface AVAssetVideoAssetAdapter : NSObject <VideoAsset>

- (id) initWithAsset:(AVAsset *)asset;

@end
