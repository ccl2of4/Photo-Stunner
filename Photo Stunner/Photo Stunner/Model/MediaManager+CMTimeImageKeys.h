//
//  MediaManager+CMTimeImageKeys.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/31/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "MediaManager.h"

@interface MediaManager (SortedImageKeys)

- (NSArray *) sortedImageKeys;
- (NSUInteger) indexOfRemovedImageKey:(NSValue *)time;
- (NSUInteger) indexOfAddedImageKey:(NSValue *)time;

@end
