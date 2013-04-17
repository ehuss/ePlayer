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

@end
