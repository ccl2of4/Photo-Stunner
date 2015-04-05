//
//  MediaManager+CMTimeRangeVideoKeys.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/31/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "MediaManager+CMTimeRangeVideoKeys.h"

@implementation MediaManager (SortedVideoKeys)

+ (NSComparisonResult (^) (id obj1, id obj2)) comparatorForSortingCMTimeRange {
    static NSComparisonResult (^comparator)(id obj1, id obj2) = ^NSComparisonResult(id obj1, id obj2) {
        CMTimeRange time1 = [obj1 CMTimeRangeValue];
        CMTimeRange time2 = [obj2 CMTimeRangeValue];
        
        int32_t compare = CMTimeCompare(time1.start, time2.start);
        
        return
            compare < 0 ?   NSOrderedAscending  :
            compare > 0 ?   NSOrderedDescending :
                            NSOrderedSame;
    };
    return comparator;
}

- (NSArray *) sortedVideoKeys {
    return [[self allVideoKeys] sortedArrayUsingComparator:[[self class] comparatorForSortingCMTimeRange]];
}

- (NSUInteger) indexOfRemovedVideoKey:(NSValue *)time {
    return [[self sortedVideoKeys] indexOfObject:time inSortedRange:NSMakeRange(0, [self.sortedVideoKeys count]) options:NSBinarySearchingInsertionIndex usingComparator:[[self class] comparatorForSortingCMTimeRange]];
}

- (NSUInteger) indexOfAddedVideoKey:(NSValue *)time {
    return [[self sortedVideoKeys] indexOfObject:time inSortedRange:NSMakeRange(0, [self.sortedVideoKeys count]) options:NSBinarySearchingFirstEqual usingComparator:[[self class] comparatorForSortingCMTimeRange]];
}

@end
