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
        theSharedRoot = [NSKeyedUnarchiver unarchiveObjectWithFile:[EPRoot dbPath]];
    }
    return theSharedRoot;
}

+ (EPRoot *)initialSharedRoot
{
    theSharedRoot = [[EPRoot alloc] init];
    theSharedRoot.playlists = [EPFolder folderWithName:@"Playlists"
                                             sortOrder:EPSortOrderAlpha
                                           releaseDate:[NSDate distantPast]
                                               addDate:[NSDate date]
                                              playDate:[NSDate distantPast]];
    theSharedRoot.artists = [EPFolder folderWithName:@"Artists"
                                           sortOrder:EPSortOrderAlpha
                                         releaseDate:[NSDate distantPast]
                                             addDate:[NSDate date]
                                            playDate:[NSDate distantPast]];
    theSharedRoot.albums = [EPFolder folderWithName:@"Albums"
                                          sortOrder:EPSortOrderAlpha
                                        releaseDate:[NSDate distantPast]
                                            addDate:[NSDate date]
                                           playDate:[NSDate distantPast]];
    theSharedRoot.cut = [EPFolder folderWithName:@"Cut"
                                       sortOrder:EPSortOrderManual
                                     releaseDate:[NSDate distantPast]
                                         addDate:[NSDate date]
                                        playDate:[NSDate distantPast]];
    theSharedRoot.queue = [EPFolder folderWithName:@"Queue"
                                         sortOrder:EPSortOrderManual
                                       releaseDate:[NSDate distantPast]
                                           addDate:[NSDate date]
                                          playDate:[NSDate distantPast]];
    theSharedRoot.dirty = YES;
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
        self.currentQueueIndex = [aDecoder decodeIntForKey:@"currentQueueIndex"];
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
    [aCoder encodeInt:self.currentQueueIndex forKey:@"currentQueueIndex"];
}

/*****************************************************************************/
#pragma mark - Accessors
/*****************************************************************************/
- (void)setCurrentQueueIndex:(int)currentQueueIndex
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

    f = [self.playlists folderWithUUID:uuid];
    if (f) { return f; }
    f = [self.artists folderWithUUID:uuid];
    if (f) { return f; }
    f = [self.albums folderWithUUID:uuid];
    if (f) { return f; }
    f = [self.cut folderWithUUID:uuid];
    if (f) { return f; }
    f = [self.queue folderWithUUID:uuid];
    if (f) { return f; }
    return nil;
}

- (EPSong *)songWithPersistentID:(NSNumber *)persistentID
{
    EPSong *s;

    s = [self.playlists songWithPersistentID:persistentID];
    if (s) { return s; }
    s = [self.artists songWithPersistentID:persistentID];
    if (s) { return s; }
    s = [self.albums songWithPersistentID:persistentID];
    if (s) { return s; }
    s = [self.cut songWithPersistentID:persistentID];
    if (s) { return s; }
    s = [self.queue songWithPersistentID:persistentID];
    if (s) { return s; }
    return nil;
}

@end
