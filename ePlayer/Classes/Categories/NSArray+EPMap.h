//
//  NSArray+EPMap.h
//  ePlayer
//
//  Created by Eric Huss on 4/16/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//
// See https://github.com/gerasim13/CUTools/blob/master/Cocoa%20Extensions/NSArray%2BMap.m
// for more.

#import <Foundation/Foundation.h>

@interface NSArray (EPMap)

- (NSArray*)mapWithBlock:(id (^)(id object))block;

@end
