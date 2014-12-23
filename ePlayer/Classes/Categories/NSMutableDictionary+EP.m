//
//  NSMutableDictionary+EP.m
//  ePlayer
//
//  Created by Eric Huss on 9/19/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

#import "NSMutableDictionary+EP.h"

@implementation NSMutableDictionary (EP)

- (void)ep_setOptObject:(id)object forKey:(id<NSCopying>)aKey
{
    if (object) {
        [self setObject:object forKey:aKey];
    }
}

@end
