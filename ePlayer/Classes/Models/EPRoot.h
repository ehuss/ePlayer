//
//  EPRoot.h
//  ePlayer
//
//  Created by Eric Huss on 4/29/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPFolder.h"
#import "EPSong.h"

extern NSString *kEPOrphanFolderName;

@interface EPRoot : NSObject <NSCoding>

@property (strong, nonatomic) EPFolder *playlists;
@property (strong, nonatomic) EPFolder *artists;
@property (strong, nonatomic) EPFolder *albums;
@property (strong, nonatomic) EPFolder *cut;
@property (strong, nonatomic) EPFolder *queue;
@property (strong, nonatomic) EPFolder *orphans;
@property (assign, nonatomic) BOOL dirty;
// This is the index of the song that is currently playing in _queue.
@property (assign, nonatomic) NSInteger currentQueueIndex;

// Return the shared root.  If it has not been loaded from disk, it will be
// loaded.  If it doesn't exist, an empty root will be returned (marked dirty).
+ (EPRoot *)sharedRoot;
+ (NSString *)dbPath;

- (void)save;
- (EPFolder *)getOrMakeOraphans;
- (EPFolder *)folderWithUUID:(NSUUID *)uuid;
- (EPSong *)songWithPersistentID:(NSNumber *)persistentID;
- (NSArray *)topFolders;
// Erases all in-memory information.
- (void)reset;
#ifdef TARGET_IPHONE_SIMULATOR
- (void)createSimulatedData;
#endif

@end
