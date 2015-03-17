//
//  VideoAsset.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol VideoAsset <NSObject>

- (UIImage *) thumbnail;
- (CGFloat) duration;
- (NSURL *) contentURL;

@end
