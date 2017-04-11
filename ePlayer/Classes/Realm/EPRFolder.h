//
//  EPRFolder.h
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import <Realm/Realm.h>
#import "EPREntry.h"
#import "EPCommon.h"
#import "EPRSong.h"

@interface EPRFolder : EPREntry
@property EPSortOrder sortOrder;
@property RLMArray<EPREntry *><EPREntry> *entries;
@property NSTimeInterval duration;

+ (EPRFolder *)folderWithName:(NSString *)name
                    sortOrder:(EPSortOrder)sortOrder
                  releaseDate:(NSDate *)releaseDate
                      addDate:(NSDate *)addDate
                     playDate:(NSDate *)palyDate;

- (NSString *)sectionTitleForEntry:(EPREntry *)entry forIndex:(BOOL)forIndex;
// Beware that this array is a snapshot, any modifications to the
// folder will not be reflected.
- (NSArray *)sortedEntries;
- (EPRFolder *)folderWithUUID:(NSUUID *)uuid;
- (EPRSong *)songWithPersistentID:(long long)persistentID;
// Remove this folder if it is empty (and it is not a top-level folder).
- (void)removeIfEmpty:(RLMRealm *)realm;
- (EPRFolder *)folderWithName:(NSString *)name;

- (void)insertObject:(EPREntry *)value inEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx;
// - (void)insertEntries:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
// - (void)removeEntriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(EPREntry *)value;
// - (void)replaceEntriesAtIndexes:(NSIndexSet *)indexes withEntries:(NSArray *)values;
- (void)addEntriesObject:(EPREntry *)value;
- (void)removeEntriesObject:(EPREntry *)value;
- (void)addEntries:(NSArray *)values;
- (void)removeEntries:(NSArray *)values;
- (void)removeAllEntries;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<EPRFolder>
RLM_ARRAY_TYPE(EPRFolder)
