//
//  LibraryLoader.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/16/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibraryLoader : NSObject

extern NSString const * LibraryLoadeVideosChangedNotification;

+ (LibraryLoader *) sharedInstance;
- (void) loadVideos:(void(^)(NSArray *videos))completion;


@end
