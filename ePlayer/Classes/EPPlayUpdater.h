//
//  EPPlayUpdater.h
//  ePlayer
//
//  Created by Eric Huss on 4/23/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPCommon.h"

@interface EPPlayUpdater : NSObject

- (id)initWithStore:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (void)spawnBgThread;
// Array of NSNumber persistentID's of media items.
- (void)enqueueItems:(NSArray *)items;

@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext *mainMOC;
@property (strong, nonatomic) NSMutableArray *incomingItems;
@property (strong, nonatomic) NSCondition *condition;

@end
