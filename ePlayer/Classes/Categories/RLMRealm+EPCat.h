//
//  RLMRealm+EPCat.h
//  ePlayer
//
//  Created by Eric Huss on 4/15/17.
//  Copyright © 2017 Eric Huss. All rights reserved.
//

#import <Realm/Realm.h>

@interface RLMRealm (EPCat)

// Beware, this isn't really a nested transaction.
- (void)epInnerTransactionWithBlock:(nonnull void (^)(void))block;

@end
