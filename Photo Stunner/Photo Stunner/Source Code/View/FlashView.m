//
//  FlashView.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/20/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "FlashView.h"

@implementation FlashView

- (void) commonInit {
    [self setAlpha:0.0f];
    [self setHidden:YES];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)flash {
    [self setAlpha:0.0f];
    [self setHidden:NO];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         
        [self setAlpha:0.4];
                     
    } completion:^(BOOL finished) {
        
        if (!finished) return;
                         
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             
            [self setAlpha:0.0];

        } completion:^(BOOL finished) {
            
            if (!finished) return;
            
            [self setHidden:YES];
    
        }];
    }];
}

@end
