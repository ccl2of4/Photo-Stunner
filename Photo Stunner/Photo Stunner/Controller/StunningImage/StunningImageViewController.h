//
//  StunningImageViewController.h
//  Photo Stunner
//
//  Created by Ryan Brooks on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MediaManager;

@interface StunningImageViewController : UIViewController

@property (nonatomic) MediaManager *mediaManager;
@property (nonatomic) NSIndexPath *activeIndexPath;

@end
