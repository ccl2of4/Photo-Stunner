//
//  ALAssetVideoAssetAdapter.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "VideoAsset.h"

@interface ALAssetVideoAssetAdapter : NSObject <VideoAsset>

- (id) initWithAsset:(ALAsset *)asset;

@end
