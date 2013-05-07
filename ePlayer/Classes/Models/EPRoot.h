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
@property (assign, nonatomic) int currentQueueIndex;

+ (EPRoot *)sharedRoot;
+ (NSString *)dbPath;
+ (EPRoot *)initialSharedRoot;

- (void)save;
- (EPFolder *)getOrMakeOraphans;
- (EPFolder *)folderWithUUID:(NSUUID *)uuid;
- (EPSong *)songWithPersistentID:(NSNumber *)persistentID;
- (NSArray *)topFolders;

@end
