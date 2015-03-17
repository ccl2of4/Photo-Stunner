//
//  TapViewController.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "TapViewController.h"
#import "ImageManager.h"
#import <AVFoundation/AVFoundation.h>

@interface TapViewController ()

@property (weak, nonatomic) IBOutlet UIView *playbackView;

@property (nonatomic) AVAssetImageGenerator *imageGenerator;
@property (nonatomic) AVPlayer *player;

@end

@implementation TapViewController

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setRightBarButtonItem: [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(handleUIControlEventTouchUpInside:)]];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.player play];
}

#pragma mark UI events

- (IBAction)handleUIGestureRecognizerRecognized:(id)sender {
    if ([sender isKindOfClass:[UITapGestureRecognizer class]] && [sender view] == self.playbackView) {
        [self extractImageAtTime:[self.player currentTime] completion:^(CMTime time, CGImageRef result) {
            UIImage *image = [UIImage imageWithCGImage:result];
            [[ImageManager sharedManager] setImage:image forTime:time];
        }];
    } else {
        assert (NO);
    }
}

- (void) handleUIControlEventTouchUpInside:(id)sender{
    assert(self.navigationController);
    [self.navigationController pushViewController:nil animated:YES];
}

#pragma mark logic

- (AVPlayer *)player {
    if (!_player) {
        AVPlayer *player = [AVPlayer playerWithURL:[self assetURL]];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        
        [player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        
        [self.playbackView.layer addSublayer:playerLayer];
        [playerLayer setFrame:[self.playbackView.layer bounds]];
        
        _player = player;
    }
    
    return _player;
}

- (void) extractImageAtTime:(CMTime)time completion:(void(^)(CMTime time, CGImageRef result))completion {
    if (![self imageGenerator]) {
        AVAsset *asset = [AVAsset assetWithURL:[self assetURL]];
        self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        [self.imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
        [self.imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    }
    
    NSArray *times = @[[NSValue valueWithCMTime:time]];
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        if ( result == AVAssetImageGeneratorSucceeded ) {
            assert (image != nil);
            completion (requestedTime, image);
            
        } else {
            completion (requestedTime, nil);
        }
    }];
}

@end
