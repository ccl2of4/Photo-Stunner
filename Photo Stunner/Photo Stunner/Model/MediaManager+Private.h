//
//  MediaManager+Private.h
//  Photo Stunner
//
//  Created by Connor Lirot on 4/5/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "MediaManager.h"

@interface MediaManager (Private)

// Notification Key
extern NSString * const MediaManagerContentChangedNotification;

// ==============
//
// Change Type
//
// ==============
extern NSString * const MediaManagerContentChangeTypeKey;
typedef enum {
    MediaManagerContentChangeAdd,
    MediaManagerContentChangeRemove
} MediaManagerContentChangeType;


// ==============
//
// Content Type
//
// ==============
extern NSString * const MediaManagerContentTypeKey;
extern NSString * const MediaManagerContentTypeImage;
extern NSString * const MediaManagerContentTypeVideo;

// Key for changed content's key
extern NSString * const MediaManagerContentKey;

@end
