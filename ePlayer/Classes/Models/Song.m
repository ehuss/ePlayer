//
//  Song.m
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "Song.h"
#import "EPMediaItemWrapper.h"

@implementation Song

@dynamic persistentID;

- (NSNumber *)UPID
{
    return [NSNumber numberWithUnsignedLongLong:[self.persistentID unsignedLongLongValue]];
}

- (MPMediaItem *)mediaItem
{
    if (_mediaItem == nil) {
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate
                                          predicateWithValue:self.persistentID
                                          forProperty:MPMediaItemPropertyPersistentID];
        [query addFilterPredicate:pred];
        NSArray *result = query.items;
        if (result.count) {
            _mediaItem = result[0];
        } else {
            NSLog(@"Failed to fetch MPMediaItem for %@ %@.", self.persistentID, self.name);
        }
    }
    return _mediaItem;
}

- (EPMediaItemWrapper *)mediaWrapper
{
    if (_mediaWrapper == nil) {
        _mediaWrapper = [EPMediaItemWrapper wrapperFromItem:self.mediaItem];
    }
    return _mediaWrapper;
}

- (NSTimeInterval)duration
{
    NSNumber *d = [self.mediaItem valueForProperty:MPMediaItemPropertyPlaybackDuration];
    return [d doubleValue];
}

@end
