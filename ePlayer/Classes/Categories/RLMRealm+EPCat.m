//
//  RLMRealm+EPCat.m
//  ePlayer
//
//  Created by Eric Huss on 4/15/17.
//  Copyright © 2017 Eric Huss. All rights reserved.
//

#import "RLMRealm+EPCat.h"

@implementation RLMRealm (EPCat)

- (void)epInnerTransactionWithBlock:(nonnull void (^)(void))block
{
    if (self.inWriteTransaction) {
        block();
    } else {
        [self beginWriteTransaction];
        block();
        [self commitWriteTransaction];
    }
}


@end
