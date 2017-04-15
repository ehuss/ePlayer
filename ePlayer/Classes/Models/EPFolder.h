//
//  EPFolder.h
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import <Realm/Realm.h>
#import "EPEntry.h"
#import "EPCommon.h"
#import "EPSong.h"

@class EPFolder;
// This protocol enables typed collections. i.e.:
// RLMArray<EPFolder>
RLM_ARRAY_TYPE(EPFolder)

@interface EPFolder : EPEntry
@property EPSortOrder sortOrder;
@property RLMArray<EPFolder *><EPFolder> *folders;
@property RLMArray<EPSong *><EPSong> *songs;
@property (readonly) RLMLinkingObjects *folderParents;
@property NSTimeInterval duration;

+ (EPFolder *)folderWithName:(NSString *)name
                    sortOrder:(EPSortOrder)sortOrder
                  releaseDate:(NSDate *)releaseDate
                      addDate:(NSDate *)addDate
                     playDate:(NSDate *)palyDate;

- (NSString *)sectionTitleForEntry:(EPEntry *)entry forIndex:(BOOL)forIndex;
// Beware that this array is a snapshot, any modifications to the
// folder will not be reflected.
- (NSArray *)sortedEntries;


- (void)moveFolderAtIndex:(NSUInteger)sourceIndex
                  toIndex:(NSUInteger)destinationIndex;
- (void)moveSongAtIndex:(NSUInteger)sourceIndex
                toIndex:(NSUInteger)destinationIndex;
- (void)insertFolder:(EPFolder *)folder atIndex:(NSUInteger)idx;
- (void)replaceFolderAtIndex:(NSUInteger)index
                  withFolder:(EPFolder *)folder;

- (void)addFolder:(EPFolder *)folder;
- (void)addSong:(EPSong *)song;
- (void)addEntry:(EPEntry *)entry;
- (void)addSongs:(id <NSFastEnumeration>)songs;
- (void)addFolders:(id <NSFastEnumeration>)folders;

- (void)removeSong:(EPSong *)song;
- (void)removeFolder:(EPFolder *)folder;
- (void)removeEntry:(EPEntry *)entry;
- (void)removeAllEntries;
- (void)removeEntries:(id <NSFastEnumeration>)entries;



// Remove this folder if it is empty (and it is not a top-level folder).
- (void)removeIfEmpty:(RLMRealm *)realm;
// Does a shallow search for a folder in this folder with the given name.
- (EPFolder *)folderWithName:(NSString *)name;

@end

