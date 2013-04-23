//
//  NSArray+EPMap.m
//  ePlayer
//
//  Created by Eric Huss on 4/16/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "NSArray+EPMap.h"

@implementation NSArray (EPMap)

- (NSArray*)mapWithBlock:(id (^)(id object))block {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
	for (id object in self) {
		id result = block(object);
        [array addObject:result ? result : [NSNull null]];
	}
	return array;
}

@end
