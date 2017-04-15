//
//  RLMCollection+EPRealm.h
//  ePlayer
//
//  Created by Eric Huss on 4/11/17.
//  Copyright © 2017 Eric Huss. All rights reserved.
//

#import <Realm/Realm.h>

// This is extending the RLMCollection protocol.
// However, Objective-C does not allow that, so this is
// somewhat of a hack around it.
@interface NSObject (EPRealm)

// Only works on RLMCollection objects.
- (NSArray *)realmMapWithBlock:(id (^)(id object))block;
// Only works on RLMCollection objects.
- (NSArray *)realmToArray;

@end

@interface RLMResults (EPRealm)
- (BOOL)epRealmContainsObject:(RLMObject *)object;
@end
