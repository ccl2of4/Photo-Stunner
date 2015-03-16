//
//  LibraryLoader.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "VideoLoader.h"

@implementation VideoLoader

NSString const * VideoLoaderModelChangedNotification = @"videoloader model changed notification";

+ (VideoLoader *)sharedInstance {
    static VideoLoader *singleton = nil;
    if (!singleton) {
        singleton = [VideoLoader new];
    }
    return singleton;
}

- (void)loadVideos:(void (^)(NSArray *videos))completion {
    completion (nil);
}

@end
