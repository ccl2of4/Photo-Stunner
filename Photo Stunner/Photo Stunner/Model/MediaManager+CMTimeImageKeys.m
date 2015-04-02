//
//  MediaManager+CMTimeImageKeys.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/31/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import "MediaManager+CMTimeImageKeys.h"

@implementation MediaManager (SortedImageKeys)

+ (NSComparisonResult (^) (id obj1, id obj2)) comparatorForSortingImageKeys {
    static NSComparisonResult (^comparator)(id obj1, id obj2) = ^NSComparisonResult(id obj1, id obj2) {
        CMTime time1 = [obj1 CMTimeValue];
        CMTime time2 = [obj2 CMTimeValue];
        
        int32_t compare = CMTimeCompare(time1, time2);
        
        return
            compare < 0 ?   NSOrderedAscending  :
            compare > 0 ?   NSOrderedDescending :
                            NSOrderedSame;
    };
    return comparator;
}

- (NSArray *) sortedImageKeys {
    return [[self allImageKeys] sortedArrayUsingComparator:[[self class] comparatorForSortingImageKeys]];
}

- (NSUInteger) indexOfRemovedImageKey:(NSValue *)time {
    return [[self sortedImageKeys] indexOfObject:time inSortedRange:NSMakeRange(0, [self.sortedImageKeys count]) options:NSBinarySearchingInsertionIndex usingComparator:[[self class] comparatorForSortingImageKeys]];
}

- (NSUInteger) indexOfAddedImageKey:(NSValue *)time {
    return [[self sortedImageKeys] indexOfObject:time inSortedRange:NSMakeRange(0, [self.sortedImageKeys count]) options:NSBinarySearchingFirstEqual usingComparator:[[self class] comparatorForSortingImageKeys]];
}

@end
