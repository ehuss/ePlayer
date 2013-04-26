//
//  EPPlayUpdater.m
//  ePlayer
//
//  Created by Eric Huss on 4/23/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "EPPlayUpdater.h"
#import "EPMediaItemWrapper.h"

@implementation EPPlayUpdater

- (id)initWithStore:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    self = [super init];
    if (self) {
        self.persistentStoreCoordinator = persistentStoreCoordinator;
        self.condition = [[NSCondition alloc] init];
        self.incomingItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)spawnBgThread
{
    NSThread *thread = [[NSThread alloc] initWithTarget:self
                                               selector:@selector(run)
                                                 object:nil];
    thread.threadPriority = 0.1;
    [thread start];
//    [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
}

- (void)run
{
    // Initialization.
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    [self performSelectorOnMainThread:@selector(registerNotification)
                           withObject:nil waitUntilDone:NO];

    while (1) {
        [self.condition lock];
        while (self.incomingItems.count == 0) {
            [self.condition wait];
        }
        NSArray *items = self.incomingItems;
        self.incomingItems = [[NSMutableArray alloc] init];
        [self.condition unlock];
        [self processItems:items];
    }
}

- (void)registerNotification
{
    // This runs on main thread.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.managedObjectContext];
}

- (void)processItems:(NSArray *)items
{
    BOOL updated = NO;
    for (NSNumber *persistentID in items) {
        // Get the MPMediateItem for this ID.
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate
                                          predicateWithValue:persistentID
                                          forProperty:MPMediaItemPropertyPersistentID];
        [query addFilterPredicate:pred];
        NSArray *result = query.items;
        if (!result.count) {
            NSLog(@"Failed to fetch MPMediaItem for persistent ID song %@.", persistentID);
            continue;
        }
        MPMediaItem *item = result[0];
        EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:item];
        // Fetch the Song object for this item.
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song"
                                                  inManagedObjectContext:self.managedObjectContext];
        request.entity = entity;
        request.predicate = [NSPredicate predicateWithFormat:@"persistentID==%@", persistentID];
        NSError *error;
        NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (results == nil || results.count==0) {
            NSLog(@"Failed to query for entries: %@", error);
            continue;
        }
        Song *song = results[0];
        // Check play count and date.
        //NSLog(@"Adjusting play count for %@", song.name);
        if ([song.playDate compare:wrapper.lastPlayedDate] != NSOrderedSame) {
            [song propagatePlayDate:wrapper.lastPlayedDate];
            NSLog(@"New play date: %@", song.playDate);
            updated = YES;
        }
        if ([song.playCount compare:wrapper.playCount] != NSOrderedSame) {
            int songCount = [song.playCount intValue];
            int wrapperCount = [wrapper.playCount intValue];
            if (wrapperCount > songCount) {
                // XXX FIXME
                //[song propagatePlayCount:[NSNumber numberWithInt:wrapperCount-songCount]];
                NSLog(@"Updated play count for %@", song.name);
                updated = YES;
            }
        }        
    }
    if (updated) {
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Failed to save: %@", error);
        }
    }
    [self.managedObjectContext reset];
}

- (void)enqueueItems:(NSArray *)items
{
    [self.condition lock];
    [self.incomingItems addObjectsFromArray:items];
    [self.condition signal];
    [self.condition unlock];
}

- (void)saveNotification:(NSNotification *)notification
{
    // This runs on main thread.
    NSLog(@"Merging changes from play count thread.");
    [self.mainMOC mergeChangesFromContextDidSaveNotification:notification];
}

@end
