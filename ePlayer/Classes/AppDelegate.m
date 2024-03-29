//
//  AppDelegate.m
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"
#import "EPCommon.h"
#import "EPMediaItemWrapper.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.initializing = YES;
    [application beginReceivingRemoteControlEvents];

    // Set up audio.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"Failed to set audio category: %@", error);
    }
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"Failed to set audio session active: %@", error);
    }
    
    // Various globals and other setup.
    createGregorianCalendar();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{EPSettingArtistsSortOrder: [NSNumber numberWithInt:EPSortOrderAlpha],
                                 EPSettingAllAbumsSortOrder: [NSNumber numberWithInt:EPSortOrderReleaseDate],
                                 EPSettingArtistAlbumsSortOrder: [NSNumber numberWithInt:EPSortOrderReleaseDate]}];
    playlistPasteboard = [UIPasteboard pasteboardWithName:@"org.ehuss.ePlayer" create:YES];
    playlistPasteboard.persistent = YES;

    self.mainTabController = (EPMainTabController *)self.window.rootViewController;
    [self.mainTabController mainInit];

    [self checkAccess:[MPMediaLibrary authorizationStatus]];

    return YES;
}

- (void)checkAccess:(MPMediaLibraryAuthorizationStatus)status
{
    switch (status) {
        // Weird compiler issue requires a block here due to the inner block.
        case MPMediaLibraryAuthorizationStatusNotDetermined: {
            // Ask the user for access.
            [MPMediaLibrary requestAuthorization: ^(MPMediaLibraryAuthorizationStatus status) {
                [self checkAccess:status];
            }];
            }
            break;
        case MPMediaLibraryAuthorizationStatusDenied:
        case MPMediaLibraryAuthorizationStatusRestricted:
            [self reallyAskForAccess];
            break;
        case MPMediaLibraryAuthorizationStatusAuthorized:
            [self libraryAccessAuthorized];
            break;
    }
}

- (void)reallyAskForAccess
{
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Media Permission Required"
                                message:@"This app requires premission to your music library in order to work.  Please enable in Settings."
                                preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Don't Allow"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Go To Settings"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }]];
    // Window isn't yet key, which prevents alert from showing.  Fix it.
    [self.window makeKeyAndVisible];
    [self.mainTabController presentViewController:alert animated:YES completion:nil];
}

- (void)libraryAccessAuthorized
{
    if ([self loadData]) {
        // Database is ready.  Populate the view.
        // XXX restore state
        [self.mainTabController loadInitialFolders];
        self.initializing = NO;
    } else {
        // Database import happens in background.
        // Don't display anything until it is done.
    }

    [self.mainTabController.playerController mainInit];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//    NSLog(@"Will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    NSLog(@"did enter background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//    NSLog(@"will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    NSLog(@"did become active");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"will term");
}

/*****************************************************************************/
#pragma mark - Remote Control
/*****************************************************************************/

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    [self.mainTabController.playerController handleRemoteControlEvent:event];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

/*****************************************************************************/
#pragma mark - Database
/*****************************************************************************/

NSString *artistNameFromMediaItem(MPMediaItem *item)
{
    NSString *artistName = [item valueForProperty:MPMediaItemPropertyAlbumArtist];
    if (artistName == nil) {
        artistName = [item valueForProperty:MPMediaItemPropertyArtist];
        if (artistName == nil) {
            NSLog(@"Error: could not determine artist name of album.");
            return nil;
        }
    }
    return artistName;
}

- (BOOL)loadData
{
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"in the simulater");
    EPRoot *root = [EPRoot sharedRoot];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [root reset];
    [root createSimulatedData];
    [realm commitWriteTransaction];
    return YES;
#else
    // First determine if there is anything in the database.
    BOOL wasCreated;
    [EPRoot sharedRoot:&wasCreated];
    if (!wasCreated) {
        // Was loaded from disk.
        return YES;
    }
    // Create the database.
    // Populate with defaults from the user's library.
    [self performSelectorInBackground:@selector(initDB:) withObject:self];
    return NO;
#endif
}

- (void)resetDB
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    [realm commitWriteTransaction];
    // Force the creation of a new root.
    [EPRoot sharedRoot];
}

- (void)initDB:(NSObject *)completionDelegate
{
    self.initCompleteDelegate = completionDelegate;
    // NOTE: must delay showing SVProgressHUD until the tab controller has
    // had a chance to display its views.
    self.hudString = @"First time import...";
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    EPRoot *root = [EPRoot sharedRoot];
    // Determine the library size for the progress indicator.
    MPMediaQuery *allQuery = [MPMediaQuery songsQuery];
    NSUInteger libSize = allQuery.items.count;
    NSUInteger songsImported = 0;
    
    // Iterate over genre's for the top-level folder.
    MPMediaQuery *genreQuery = [[MPMediaQuery alloc] init];
    genreQuery.groupingType = MPMediaGroupingGenre;
    MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate
                                      predicateWithValue:@(MPMediaTypeMusic)
                                      forProperty:MPMediaItemPropertyMediaType];
    [genreQuery addFilterPredicate:pred];
    // Keep track of genre folders for later.  Key is genre name, value is Folder.
    NSMutableDictionary *genres = [[NSMutableDictionary alloc] init];
    for (MPMediaItemCollection *genre in genreQuery.collections) {
        // Create a folder for this genre.
        MPMediaItem *representativeItem = genre.representativeItem;
        NSLog(@"Genre: %@", [representativeItem valueForProperty:MPMediaItemPropertyGenre]);
        // These dates will be updated once songs are seen.
        EPFolder *genreFolder = [EPFolder folderWithName:[representativeItem valueForProperty:MPMediaItemPropertyGenre]
                                               sortOrder:EPSortOrderAddDate
                                             releaseDate:[NSDate distantPast]
                                                 addDate:[NSDate distantPast]
                                                playDate:[NSDate distantPast]];
        [root.playlists addFolder:genreFolder];
        [genres setObject:genreFolder forKey:genreFolder.name];
    }
    
    // Fetch all albums.
    MPMediaQuery *albums = [MPMediaQuery albumsQuery];
    // Keep a unique set of artists.
    NSMutableDictionary *artists = [[NSMutableDictionary alloc] init];
    // Playlists gets separate folders.
    NSMutableDictionary *playlistArtists = [[NSMutableDictionary alloc] init];
    for (MPMediaItemCollection *albumItem in albums.collections) {
        MPMediaItem *representativeItem = albumItem.representativeItem;
        // XXX: What if genre is nil?
        EPFolder *genre = [genres objectForKey:[representativeItem valueForProperty:MPMediaItemPropertyGenre]];
        NSString *artistName = artistNameFromMediaItem(representativeItem);
        if (artistName == nil) {
            continue;
        }
        
        // Create artist if it does not exist.
        EPFolder *artist = [artists objectForKey:artistName];
        if (artist == nil) {
            // Create artist folder.
            // These dates will be updated once songs are seen.
            artist = [EPFolder folderWithName:artistName
                                    sortOrder:EPSortOrderAddDate
                                  releaseDate:[NSDate distantPast]
                                      addDate:[NSDate distantPast]
                                     playDate:[NSDate distantPast]];
            [artists setObject:artist forKey:artistName];
            [root.artists addFolder:artist];
            NSLog(@"Create artist %@", artist.name);
        }
        EPFolder *playlistArtist = [playlistArtists objectForKey:artistName];
        if (playlistArtist == nil) {
            playlistArtist = [EPFolder folderWithName:artistName
                                            sortOrder:EPSortOrderAddDate
                                          releaseDate:[NSDate distantPast]
                                              addDate:playlistArtist.releaseDate
                                             playDate:[NSDate distantPast]];
            [genre addFolder:playlistArtist];
            [playlistArtists setObject:playlistArtist forKey:artistName];
        }
        // Create album folder.
        // These dates will be updated once songs are seen.
        EPFolder *albumFolder = [EPFolder folderWithName:[representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle]
                                               sortOrder:EPSortOrderManual
                                             releaseDate:[NSDate distantPast]
                                                 addDate:[NSDate distantPast]
                                                playDate:[NSDate distantPast]];
        EPFolder *playlistAlbum = [EPFolder folderWithName:albumFolder.name
                                                 sortOrder:EPSortOrderManual
                                               releaseDate:[NSDate distantPast]
                                                   addDate:playlistAlbum.releaseDate
                                                  playDate:[NSDate distantPast]];
        [artist addFolder:albumFolder];
        [playlistArtist addFolder:playlistAlbum];
        
        [root.albums addFolder:albumFolder];
        NSLog(@"Create album %@", albumFolder.name);
        
        // Add songs to album folder.
        NSInteger maxPlayCount = 0;
        for (MPMediaItem *songItem in albumItem.items) {
            EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:songItem];
            EPSong *song = [EPSong songWithName:wrapper.title
                                   persistentID:wrapper.persistentID];
            [albumFolder addSong:song];
            [playlistAlbum addSong:song];
            
            // Propagate will also set on song.
            [song propagateReleaseDate:wrapper.releaseDate];
            NSDate *date = wrapper.lastPlayedDate;
            if (date == nil) {
                date = [NSDate distantPast];
            }
            [song propagatePlayDate:date];
            [song propagateAddDate:song.releaseDate];
            NSNumber *playCount = wrapper.playCount;
            if (playCount != nil) {
                maxPlayCount = MAX(maxPlayCount, [playCount integerValue]);
            }
            song.playCount = [wrapper.playCount integerValue];
            songsImported += 1;
            [self importUpdateProgress:@((float)songsImported/(float)libSize)];
        }
        [albumFolder propagatePlayCount:maxPlayCount];
        [playlistAlbum propagatePlayCount:maxPlayCount];
#ifdef EP_MEMORY_DEBUG
        logMemUsage();
#endif
    } // end for each album.
    NSLog(@"Committing data.");
    [realm commitWriteTransaction];
    NSLog(@"Done importing...");
    [SVProgressHUD performSelectorOnMainThread:@selector(showSuccessWithStatus:) withObject:@"Complete!" waitUntilDone:NO];
    [self.initCompleteDelegate performSelectorOnMainThread:@selector(dbInitDone) withObject:nil waitUntilDone:NO];
}

- (void)importUpdateProgress:(NSNumber *)progress
{
    if (self.lastHudUpdate == nil) {
        self.lastHudUpdate = [NSDate date];
    } else {
        // Only update a few times a second.
        if ([self.lastHudUpdate timeIntervalSinceNow] > -0.2) {
            return;
        }
        self.lastHudUpdate = [NSDate date];
    }
    [self performSelectorOnMainThread:@selector(importUpdateProgress2:)
                           withObject:progress
                        waitUntilDone:NO];
}
- (void)importUpdateProgress2:(NSNumber *)progress
{
    [SVProgressHUD showProgress:progress.floatValue status:self.hudString maskType:SVProgressHUDMaskTypeGradient];
}

- (void)dbInitDone
{
    [self.mainTabController loadInitialFolders];
    self.initializing = NO;
}

- (void)beginDBUpdate:(NSObject *)sender
{
    self.dbSender = sender;
    self.hudString = @"Updating database...";
    [self performSelectorInBackground:@selector(updateDB) withObject:nil];
}

- (void)updateDB
{
    EPRoot *root = [EPRoot sharedRoot];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    // Array of EPMediaItemWrappers.
    NSMutableArray *addedSongs = [[NSMutableArray alloc] init];
    // Array of EPSongs.
    NSMutableArray *removedSongs = [[NSMutableArray alloc] init];
    NSInteger removedSongCount = 0;
    // Array of EPMediaItemWrappers.
    NSMutableArray *brokenItems = [[NSMutableArray alloc] init];
    
    // Find all the songs currently in the database.
    RLMResults *allSongs = [EPSong allObjects];

    // Create a dictionary of all items used to check for deleted songs.
    NSMutableDictionary *allItems = [[NSMutableDictionary alloc] init];

    // Determine the library size for the progress indicator.
    // NOTE: This is not perfect.  It is possible for songsQuery to return
    // more entries than albumsQuery (like songs without an album title).
    // But it should be close enough.
    MPMediaQuery *allQuery = [MPMediaQuery songsQuery];
    NSUInteger libSize = allQuery.items.count + allSongs.count;
    NSUInteger songsScanned = 0;

    // For each song not already in the database, add it.
    // Use albumsQuery because it sorts things nicely for us.
    MPMediaQuery *albumsQuery = [MPMediaQuery albumsQuery];
    for (MPMediaItemCollection *albumItem in albumsQuery.collections) {
        for (MPMediaItem *item in albumItem.items) {
            songsScanned += 1;
            [self importUpdateProgress:@((float)songsScanned/(float)libSize)];

            EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:item];
            [allItems setObject:wrapper forKey:wrapper.persistentID];
            if (![allSongs objectsWhere:@"persistentID = %@", wrapper.persistentID].count) {
                // This song needs to be added to the database.
                if (wrapper.genre == nil || wrapper.albumArtist == nil || wrapper.albumTitle == nil) {
                    [brokenItems addObject:wrapper];
                    continue;
                }
                EPSong *song = [EPSong songWithName:wrapper.title
                                       persistentID:wrapper.persistentID];
                [addedSongs addObject:wrapper];
                // Add this song to the correct places, creating folders as necessary.
                // Not going to bother propogating this (normally is zero anyways).
                song.playCount = [wrapper.playCount integerValue];

                // Determine where it should go in "playlists".
                EPFolder *genreFolder = [root.playlists folderWithName:wrapper.genre];
                if (genreFolder == nil) {
                    genreFolder = [EPFolder folderWithName:wrapper.genre
                                                 sortOrder:EPSortOrderAddDate
                                               releaseDate:[NSDate distantPast]
                                                   addDate:[NSDate distantPast]
                                                  playDate:[NSDate distantPast]];
                    [root.playlists addFolder:genreFolder];
                }
                EPFolder *genreArtist = [genreFolder folderWithName:wrapper.albumArtist];
                if (genreArtist == nil) {
                    genreArtist = [EPFolder folderWithName:wrapper.albumArtist
                                                 sortOrder:EPSortOrderAddDate
                                               releaseDate:[NSDate distantPast]
                                                   addDate:[NSDate distantPast]
                                                  playDate:[NSDate distantPast]];
                    [genreFolder addFolder:genreArtist];
                }
                EPFolder *genreAlbum = [genreArtist folderWithName:wrapper.albumTitle];
                if (genreAlbum == nil) {
                    genreAlbum = [EPFolder folderWithName:wrapper.albumTitle
                                                sortOrder:EPSortOrderManual
                                              releaseDate:[NSDate distantPast]
                                                  addDate:[NSDate distantPast]
                                                 playDate:[NSDate distantPast]];
                    [genreArtist addFolder:genreAlbum];
                }
                [genreAlbum addSong:song];

                // Determine where it should go in artists.
                EPFolder *artistFolder = [root.artists folderWithName:wrapper.albumArtist];
                if (artistFolder == nil) {
                    artistFolder = [EPFolder folderWithName:wrapper.albumArtist
                                                  sortOrder:EPSortOrderAddDate
                                                releaseDate:[NSDate distantPast]
                                                    addDate:[NSDate distantPast]
                                                   playDate:[NSDate distantPast]];
                    [root.artists addFolder:artistFolder];
                }
                
                // Determine where it should go in albums.
                EPFolder *albumFolder = [root.albums folderWithName:wrapper.albumTitle];
                if (albumFolder == nil) {
                    albumFolder = [EPFolder folderWithName:wrapper.albumTitle
                                                 sortOrder:EPSortOrderManual
                                               releaseDate:[NSDate distantPast]
                                                   addDate:[NSDate distantPast]
                                                  playDate:[NSDate distantPast]];
                    [root.albums addFolder:albumFolder];
                    // Assume album is missing in artist as well.
                    [artistFolder addFolder:albumFolder];
                }
                [albumFolder addSong:song];
                
                [song propagateAddDate:[NSDate date]];
                [song propagateReleaseDate:wrapper.releaseDate];
                song.playDate = [NSDate distantPast];
            }
        }
    }
    
    // Check if any songs have been removed.
    for (EPSong *song in allSongs) {
        if ([allItems objectForKey:song.persistentID] == nil) {
            // Remove song.
            [removedSongs addObjectsFromArray:[song pathNames]];
            removedSongCount += 1;
            // RLMResult should be frozen during fast enumeration.
            for (EPFolder *parent in song.parents) {
                [parent removeEntry:song];
                [parent removeIfEmpty:realm];
            }
        }
        songsScanned += 1;
        [self importUpdateProgress:@((float)songsScanned/(float)libSize)];
    }
    
    NSLog(@"Committing data.");
    [realm commitWriteTransaction];
    NSLog(@"Done update scan...");
    
    // Prepare a view of what's added and removed.
    NSMutableString *results = [[NSMutableString alloc] init];
    if (addedSongs.count) {
        [results appendFormat:@"Added %lu songs:\n", (unsigned long)addedSongs.count];
        for (EPMediaItemWrapper *wrapper in addedSongs) {
            [results appendFormat:@"\t%@ - %@ - %@\n", wrapper.artist, wrapper.albumTitle, wrapper.title];
        }
    } else {
        [results appendString:@"No songs added.\n"];
    }
    if (removedSongCount) {
        [results appendFormat:@"Removed %li songs:\n", (long)removedSongCount];
        for (NSString *path in removedSongs) {
            [results appendFormat:@"\t%@\n", path];
        }
    } else {
        [results appendString:@"No songs removed.\n"];
    }
    if (brokenItems.count) {
        [results appendFormat:@"Found %lu invalid songs:\n", (unsigned long)brokenItems.count];
        for (EPMediaItemWrapper *wrapper in brokenItems) {
            [results appendFormat:@"\t%@ - %@ - %@\n", wrapper.artist, wrapper.albumTitle, wrapper.title];
        }
    }
    [self performSelectorOnMainThread:@selector(updateDBDone:) withObject:results waitUntilDone:NO];
}

- (void)updateDBDone:(NSString *)results
{
    [SVProgressHUD showSuccessWithStatus:@"Complete!"];
    [self.dbSender performSelector:@selector(dbUpdateDone:) withObject:results];
}

@end
