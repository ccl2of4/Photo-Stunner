//
//  TapViewController.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "TapViewController.h"
#import "ImageManager.h"
#import "ThumbnailsViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface TapViewController ()

@property (weak, nonatomic) IBOutlet UIView *playbackView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) AVAssetImageGenerator *imageGenerator;
@property (nonatomic) AVPlayer *player;

@end

@implementation TapViewController

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(handleUIControlEventTouchUpInside:)];
    [rightBarButtonItem setEnabled:NO];
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
    
    [self.imageView setImage:[self.videoAsset thumbnail]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ImageManagerSortedTimesChangedNotification object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.player play];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UI events

- (IBAction)handleUIGestureRecognizerRecognized:(id)sender {
    if ([sender isKindOfClass:[UITapGestureRecognizer class]] && [sender view] == self.playbackView) {
        [self extractAndSaveImageAtCurrentTime];
    } else {
        assert (NO);
    }
}

- (void) handleUIControlEventTouchUpInside:(id)sender{
    assert(self.navigationController);

    ThumbnailsViewController *thumbnailsViewController = [ThumbnailsViewController new];
    [self.navigationController pushViewController:thumbnailsViewController animated:YES];
}

#pragma mark logic

- (void) extractAndSaveImageAtCurrentTime {
    [self extractImageAtTime:[self.player currentTime] completion:^(CMTime time, CGImageRef result) {
        
        assert (result);
        UIImage *image = [UIImage imageWithCGImage:result];
        assert (image);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ImageManager sharedManager] setImage:image forTime:time];
        });
    }];
}

- (void) extractImageAtTime:(CMTime)time completion:(void(^)(CMTime time, CGImageRef result))completion {
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

- (AVAssetImageGenerator *)imageGenerator {
    if (!_imageGenerator) {
        NSURL *assetURL = [self.videoAsset contentURL];
        AVAsset *asset = [AVAsset assetWithURL:assetURL];
        _imageGenerator= [[AVAssetImageGenerator alloc] initWithAsset:asset];
        [_imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
        [_imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    }
    return _imageGenerator;
}

- (AVPlayer *)player {
    if (!_player) {
        NSURL *assetURL = [self.videoAsset contentURL];
        AVPlayer *player = [AVPlayer playerWithURL:assetURL];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        
        [player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        
        [self.playbackView.layer addSublayer:playerLayer];
        [playerLayer setFrame:[self.playbackView.layer bounds]];
        
        _player = player;
    }
    
    return _player;
}

#pragma mark notification handling

- (void) handleNotification:(NSNotification *)notification {
    if ([notification name] == ImageManagerSortedTimesChangedNotification) {
        BOOL rightBarButtonItemEnabled = [[[ImageManager sharedManager] sortedTimes] count] > 0;
        [self.navigationItem.rightBarButtonItem setEnabled:rightBarButtonItemEnabled];
    } else {
        assert (NO);
    }
}




@end
