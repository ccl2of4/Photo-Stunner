//
//  MediaManager+CMTimeRangeVideoKeys.h
//  Photo Stunner
//
//  Created by Connor Lirot on 3/31/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "MediaManager.h"

@interface MediaManager (SortedVideoKeys)

- (NSArray *) sortedVideoKeys;
- (NSUInteger) indexOfRemovedVideoKey:(NSValue *)timeRange;
- (NSUInteger) indexOfAddedVideoKey:(NSValue *)timeRange;

@end
