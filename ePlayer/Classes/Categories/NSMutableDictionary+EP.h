//
//  NSMutableDictionary+EP.h
//  ePlayer
//
//  Created by Eric Huss on 9/19/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (EP)

- (void)ep_setOptObject:(id)object forKey:(id<NSCopying>)aKey;

@end
