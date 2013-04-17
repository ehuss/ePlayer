//
//  Song.h
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Entry.h"


@interface Song : Entry

@property (nonatomic, retain) NSNumber * persistentID;
// Unsigned version, since core data doesn't support unsigned.
@property (readonly, nonatomic) NSNumber *UPID;

@end
