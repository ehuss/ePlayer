//
//  Song.m
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "Song.h"


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

@end
