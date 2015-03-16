//
//  ImageManager.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@interface ImageManager : NSObject

+ (ImageManager *) sharedManager;

- (NSArray *) sortedTimes;
- (UIImage *) imageForTime:(CMTime)time;
- (void) setImage:(UIImage *)image forTime:(CMTime)time;

@end
