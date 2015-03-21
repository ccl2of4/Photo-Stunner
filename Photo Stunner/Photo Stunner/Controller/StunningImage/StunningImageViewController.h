//
//  StunningImageViewController.h
//  Photo Stunner
//
//  Created by Ryan Brooks on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ImageManager;

@interface StunningImageViewController : UIViewController

@property (nonatomic) ImageManager *imageManager;
@property (nonatomic) NSUInteger imageIndex;

@end
