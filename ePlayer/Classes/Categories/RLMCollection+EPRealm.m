//
//  RLMCollection+EPRealm.m
//  ePlayer
//
//  Created by Eric Huss on 4/11/17.
//  Copyright © 2017 Eric Huss. All rights reserved.
//

#import "RLMCollection+EPRealm.h"

@implementation NSObject (EPRealm)

- (NSArray *)realmMapWithBlock:(id (^)(id object))block {
    RLMObject<RLMCollection> *me = (RLMObject<RLMCollection>*) self;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:me.count];
    for (id object in me) {
        id result = block(object);
        [array addObject:result ? result : [NSNull null]];
    }
    return array;
}

- (NSArray *)realmToArray
{
    RLMObject<RLMCollection> *me = (RLMObject<RLMCollection>*) self;
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:me.count];

    for (id entry in me) {
        [result addObject:entry];
    }
    return result;
}

@end

@implementation RLMResults (EPRealm)

- (BOOL)epRealmContainsObject:(RLMObject *)object
{
    return [self indexOfObject:object] != NSNotFound;
}

@end
