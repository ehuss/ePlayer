//
//  EPRoot.m
//  ePlayer
//
//  Created by Eric Huss on 4/29/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPRoot.h"

NSString *kEPOrphanFolderName = @"Orphaned Songs";

@implementation EPRoot

/*****************************************************************************/
#pragma mark - Class methods
/*****************************************************************************/

+ (NSString *)dbPath
{
    NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                          NSUserDomainMask,
                                                          YES) lastObject];
    return [docs stringByAppendingPathComponent:@"ePlayer.plist"];
}

static EPRoot *theSharedRoot;
+ (EPRoot *)sharedRoot
{
    if (theSharedRoot == nil) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[EPRoot dbPath]]) {
            theSharedRoot = [NSKeyedUnarchiver unarchiveObjectWithFile:[EPRoot dbPath]];
        } else {
            theSharedRoot = [EPRoot new];
            [theSharedRoot reset];
            theSharedRoot.dirty = YES;
        }
    }
    return theSharedRoot;
}

/*****************************************************************************/
#pragma mark - NSCoding
/*****************************************************************************/

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.playlists = [aDecoder decodeObjectForKey:@"playlists"];
        self.artists = [aDecoder decodeObjectForKey:@"artists"];
        self.albums = [aDecoder decodeObjectForKey:@"albums"];
        self.cut = [aDecoder decodeObjectForKey:@"cut"];
        self.queue = [aDecoder decodeObjectForKey:@"queue"];
        self.currentQueueIndex = [aDecoder decodeIntegerForKey:@"currentQueueIndex"];
        self.dirty = NO;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.playlists forKey:@"playlists"];
    [aCoder encodeObject:self.artists forKey:@"artists"];
    [aCoder encodeObject:self.albums forKey:@"albums"];
    [aCoder encodeObject:self.cut forKey:@"cut"];
    [aCoder encodeObject:self.queue forKey:@"queue"];
    [aCoder encodeInteger:self.currentQueueIndex forKey:@"currentQueueIndex"];
}

/*****************************************************************************/
#pragma mark - Accessors
/*****************************************************************************/
- (void)setCurrentQueueIndex:(NSInteger)currentQueueIndex
{
    _currentQueueIndex = currentQueueIndex;
    _dirty = YES;
}

/*****************************************************************************/
#pragma mark - Misc
/*****************************************************************************/

- (void)save
{
    if (self.dirty) {
        NSLog(@"Save start.");
        if(![NSKeyedArchiver archiveRootObject:self toFile:[EPRoot dbPath]]) {
            NSLog(@"Failed to archive db.");
        }
        NSLog(@"Save done.");
        self.dirty = NO;
    }
}

- (EPFolder *)getOrMakeOraphans
{
    if (self.orphans == nil) {
        for (EPEntry *entry in self.playlists.entries) {
            if ([entry.name isEqualToString:kEPOrphanFolderName]) {
                self.orphans = (EPFolder *)entry;
                return self.orphans;
            }
        }
        // Didn't find it, create it.
        self.orphans = [EPFolder folderWithName:kEPOrphanFolderName
                                      sortOrder:EPSortOrderManual
                                    releaseDate:[NSDate distantPast]
                                        addDate:[NSDate date]
                                       playDate:[NSDate distantPast]];
        [self.playlists addEntriesObject:self.orphans];
    }
    return self.orphans;
}

- (EPFolder *)folderWithUUID:(NSUUID *)uuid
{
    EPFolder *f;

    for (EPFolder *folder in [self topFolders]) {
        f = [folder folderWithUUID:uuid];
        if (f) { return f; }
    }
    return nil;
}

- (EPSong *)songWithPersistentID:(NSNumber *)persistentID
{
    EPSong *s;
    
    for (EPFolder *folder in [self topFolders]) {
        s = [folder songWithPersistentID:persistentID];
        if (s) { return s; }
    }
    return nil;
}

- (NSArray *)topFolders
{
    return @[self.playlists,
             self.artists,
             self.albums,
             self.cut,
             self.queue];
}

- (void)reset
{
    _playlists = [EPFolder folderWithName:@"Playlists"
                                sortOrder:EPSortOrderAlpha
                              releaseDate:[NSDate distantPast]
                                  addDate:[NSDate date]
                                 playDate:[NSDate distantPast]];
    _artists = [EPFolder folderWithName:@"Artists"
                              sortOrder:EPSortOrderAlpha
                            releaseDate:[NSDate distantPast]
                                addDate:[NSDate date]
                               playDate:[NSDate distantPast]];
    _albums = [EPFolder folderWithName:@"Albums"
                             sortOrder:EPSortOrderAlpha
                           releaseDate:[NSDate distantPast]
                               addDate:[NSDate date]
                              playDate:[NSDate distantPast]];
    _cut = [EPFolder folderWithName:@"Cut"
                          sortOrder:EPSortOrderManual
                        releaseDate:[NSDate distantPast]
                            addDate:[NSDate date]
                           playDate:[NSDate distantPast]];
    _queue = [EPFolder folderWithName:@"Queue"
                            sortOrder:EPSortOrderManual
                          releaseDate:[NSDate distantPast]
                              addDate:[NSDate date]
                             playDate:[NSDate distantPast]];
    _dirty = YES;
    _currentQueueIndex = 0;
}

@end
