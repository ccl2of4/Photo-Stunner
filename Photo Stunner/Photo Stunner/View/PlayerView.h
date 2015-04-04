//
//  PlayerView.h
//  Photo Stunner
//
//  Created by Connor Lirot on 4/3/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class PlayerView;

@protocol PlayerViewDelegate <NSObject>

- (void) playerView:(PlayerView *)playerView didSelectImageAtTime:(CMTime)time;

- (void) playerView:(PlayerView *)playerView didStartVideoSelection:(CMTimeRange)startTimeRange;
- (void) playerView:(PlayerView *)playerView didCancelVideoSelection:(CMTimeRange)timeRange;
- (void) playerView:(PlayerView *)playerView didUpdateVideoSelection:(CMTimeRange)updatedTimeRange
                                                        oldTimeRange:(CMTimeRange)oldTimeRange
                                                            finished:(BOOL)finished;

@end

@interface PlayerView : UIView

@property (nonatomic) CMTime minimumVideoDuration;
@property (nonatomic) AVPlayer *player;
@property (nonatomic, weak) id<PlayerViewDelegate> delegate;
@property (nonatomic) UIImage *thumbnailImage;

@end
