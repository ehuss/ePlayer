//
//  EPRoot.m
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import "EPRoot.h"

@implementation EPRoot

/*****************************************************************************/
#pragma mark - Realm
/*****************************************************************************/

// Specify default values for properties

//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

- (void)transUpdateIndex:(NSInteger)newIndex
{
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        self.currentQueueIndex = newIndex;
    }];
}

/*****************************************************************************/
#pragma mark - Class methods
/*****************************************************************************/

+ (EPRoot *)sharedRoot:(BOOL *)wasCreated
{
    RLMResults *roots = [EPRoot allObjects];
    if (roots.count) {
        *wasCreated = NO;
        return roots[0];
    } else {
        // Create a new root.
        EPRoot *root = [EPRoot new];
        [root reset];
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [realm addObject:root];
        [realm commitWriteTransaction];
        *wasCreated = YES;
        return root;
    }
}

+ (EPRoot *)sharedRoot
{
    BOOL wasCreated;
    return [EPRoot sharedRoot:&wasCreated];
}


/*****************************************************************************/
#pragma mark - Misc
/*****************************************************************************/

- (void)reset
{
    self.playlists = [EPFolder folderWithName:@"Playlists"
                                     sortOrder:EPSortOrderAlpha
                                   releaseDate:[NSDate distantPast]
                                       addDate:[NSDate date]
                                      playDate:[NSDate distantPast]];
    self.artists = [EPFolder folderWithName:@"Artists"
                                   sortOrder:EPSortOrderAlpha
                                 releaseDate:[NSDate distantPast]
                                     addDate:[NSDate date]
                                    playDate:[NSDate distantPast]];
    self.albums = [EPFolder folderWithName:@"Albums"
                                  sortOrder:EPSortOrderAlpha
                                releaseDate:[NSDate distantPast]
                                    addDate:[NSDate date]
                                   playDate:[NSDate distantPast]];
    self.cut = [EPFolder folderWithName:@"Cut"
                               sortOrder:EPSortOrderManual
                             releaseDate:[NSDate distantPast]
                                 addDate:[NSDate date]
                                playDate:[NSDate distantPast]];
    self.queue = [EPFolder folderWithName:@"Queue"
                                 sortOrder:EPSortOrderManual
                               releaseDate:[NSDate distantPast]
                                   addDate:[NSDate date]
                                  playDate:[NSDate distantPast]];
    self.currentQueueIndex = 0;
}

#ifdef TARGET_IPHONE_SIMULATOR
- (void)createSimulatedData
{
    // Add some general playlist categories.
    NSArray *categories = @[@"General", @"Classical", @"Soundtracks"];
    for (NSString *name in categories) {
        EPFolder *folder = [EPFolder folderWithName:name
                                            sortOrder:EPSortOrderAlpha
                                          releaseDate:[NSDate distantPast]
                                              addDate:[NSDate date]
                                             playDate:[NSDate distantPast]];
        [self.playlists addFolder:folder];
    }
    // Create a bunch of artists.
    // Some letters to use for the first character.
    // TODO: Consider trying lowercase and tricky Unicode characters here.
    NSString *firstChars = @"1ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (NSUInteger i=0; i<firstChars.length; i++) {
        unichar c = [firstChars characterAtIndex:i];
        NSString *artistName = [NSString stringWithCharacters:&c length:1];
        artistName = [NSString stringWithFormat:@"%@ Artist Name", artistName];
        // Artist folder.
        EPFolder *artistFolder = [EPFolder folderWithName:artistName
                                                  sortOrder:EPSortOrderAddDate releaseDate:[NSDate distantPast]
                                                    addDate:[NSDate distantPast]
                                                   playDate:[NSDate distantPast]];
        [self.artists addFolder:artistFolder];
        // Playlist artist folder.
        EPFolder *playlistArtist = [EPFolder folderWithName:artistName
                                                  sortOrder:EPSortOrderAddDate releaseDate:[NSDate distantPast]
                                                    addDate:[NSDate distantPast]
                                                   playDate:[NSDate distantPast]];
        // XXX Spread across the genres.
        EPFolder *genFolder = self.playlists.folders[0];
        [genFolder addFolder:playlistArtist];
        // Album folder (both genre and artist).
        for (NSUInteger albumIndex=0; albumIndex<3; albumIndex++) {
            NSString *albumName = [NSString stringWithFormat:@"Artist %@'s %lu Album", artistName, (unsigned long)albumIndex+1];
            EPFolder *albumFolder = [EPFolder folderWithName:albumName
                                                     sortOrder:EPSortOrderManual
                                                   releaseDate:[NSDate distantPast]
                                                       addDate:[NSDate distantPast]
                                                      playDate:[NSDate distantPast]];
            EPFolder *playlistAlbum = [EPFolder folderWithName:albumName
                                                     sortOrder:EPSortOrderManual
                                                   releaseDate:[NSDate distantPast]
                                                       addDate:[NSDate distantPast]
                                                      playDate:[NSDate distantPast]];
            [artistFolder addFolder:albumFolder];
            [playlistArtist addFolder:playlistAlbum];
            [self.albums addFolder:albumFolder];

            // Songs.
            for (NSUInteger songIndex=0; songIndex<12; songIndex++) {
                NSString *songName = [NSString stringWithFormat:@"Song Name %lu", (unsigned long)songIndex+1];
                EPSong *song = [EPSong songWithName:songName
                                         persistentID:[NSNumber numberWithLongLong:0]];
                [albumFolder addSong:song];
                [playlistAlbum addSong:song];
                // XXX Set date and propogate.
            }
        }
    }
}
#endif

@end
