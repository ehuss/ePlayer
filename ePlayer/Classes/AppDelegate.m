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
//    [[NSFileManager defaultManager] removeItemAtPath:[EPRoot dbPath] error:nil];

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
    
    // Core data setup.
    self.mainTabController = (EPMainTabController *)self.window.rootViewController;
    [self.mainTabController mainInit];
    
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

    return YES;
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
    if (!self.initializing) {
        EPRoot *root = [EPRoot sharedRoot];
        [root save];
    }
    
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
    // First determine if there is anything in the database.
    if ([[NSFileManager defaultManager] fileExistsAtPath:[EPRoot dbPath]]) {
        EPRoot *root = [EPRoot sharedRoot];
        if (root == nil) {
            // This should not be possible.  Only returns nil on file-not-found.
            // Otherwise raises an exception.
            abort();
        }
        return YES;
    }
    // Create the database.
    // Populate with defaults from the user's library.
    [self showProgressAlert:@"Importing..." message:@"Performing first time import."];
    [self performSelectorInBackground:@selector(initDB) withObject:nil];
    return NO;
}

- (void)showProgressAlert:(NSString *)title message:(NSString *)message
{
    // Display a progress indicator.
    self.importAlertView = [[UIAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:nil];
    [self.importAlertView show];
    self.importProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    // This is rather hacky.  The alertView frame is an odd size (presumably
    // for all the shadowing).  It's unfortunate that UIAlertView does not
    // have a formal way to add accessory views.
    // The Right Thing to do would be to make a custom view.
    CGRect pvf = self.importProgressView.frame;
    self.importProgressView.frame = CGRectMake(20, 96,
                                               242, pvf.size.height);
    
    [self.importAlertView addSubview:self.importProgressView];
    
}

- (void)initDB
{
    EPRoot *root = [EPRoot initialSharedRoot];
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
        [root.playlists addEntriesObject:genreFolder];
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
            [root.artists addEntriesObject:artist];
            NSLog(@"Create artist %@", artist.name);
        }
        EPFolder *playlistArtist = [playlistArtists objectForKey:artistName];
        if (playlistArtist == nil) {
            playlistArtist = [artist copy];
            playlistArtist.addDate = playlistArtist.releaseDate;
            [genre addEntriesObject:playlistArtist];
            [playlistArtists setObject:playlistArtist forKey:artistName];
        }
        // Create album folder.
        // These dates will be updated once songs are seen.
        EPFolder *albumFolder = [EPFolder folderWithName:[representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle]
                                               sortOrder:EPSortOrderManual
                                             releaseDate:[NSDate distantPast]
                                                 addDate:[NSDate distantPast]
                                                playDate:[NSDate distantPast]];
        EPFolder *playlistAlbum = [albumFolder copy];
        playlistAlbum.addDate = playlistAlbum.releaseDate;
        
        [artist addEntriesObject:albumFolder];
        [playlistArtist addEntriesObject:playlistAlbum];
        
        [root.albums addEntriesObject:albumFolder];
        NSLog(@"Create album %@", albumFolder.name);
        
        // Add songs to album folder.
        NSUInteger maxPlayCount = 0;
        for (MPMediaItem *songItem in albumItem.items) {
            EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:songItem];
            EPSong *song = [EPSong songWithName:wrapper.title
                                   persistentID:wrapper.persistentID];
            [albumFolder addEntriesObject:song];
            [playlistAlbum addEntriesObject:song];
            
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
            [self performSelectorOnMainThread:@selector(importUpdateProgress:)
                                   withObject:@((float)songsImported/(float)libSize)
                                waitUntilDone:NO];
        }
        [albumFolder propagatePlayCount:maxPlayCount];
        [playlistAlbum propagatePlayCount:maxPlayCount];
#ifdef EP_MEMORY_DEBUG
        logMemUsage();
#endif
    } // end for each album.
    NSLog(@"Committing data.");
    [root save];
    NSLog(@"Done importing...");
    [self performSelectorOnMainThread:@selector(importDone) withObject:nil waitUntilDone:NO];
}

- (void)importUpdateProgress:(NSNumber *)progress
{
    [self.importProgressView setProgress:progress.floatValue animated:YES];
}

- (void)importDone
{
    [self.importAlertView dismissWithClickedButtonIndex:0 animated:YES];
    [self.mainTabController loadInitialFolders];
    self.initializing = NO;
}

- (void)beginDBUpdate:(NSObject *)sender
{
    self.dbSender = sender;
    [self showProgressAlert:@"Scanning..." message:@"Updating database."];
    [self performSelectorInBackground:@selector(updateDB) withObject:nil];
}

- (void)updateDB
{
    EPRoot *root = [EPRoot sharedRoot];
    // Array of EPMediaItemWrappers.
    NSMutableArray *addedSongs = [[NSMutableArray alloc] init];
    // Array of EPSongs.
    NSMutableArray *removedSongs = [[NSMutableArray alloc] init];
    NSInteger removedSongCount = 0;
    // Array of EPMediaItemWrappers.
    NSMutableArray *brokenItems = [[NSMutableArray alloc] init];
    
    // Find all the songs currently in the database.
    NSMutableDictionary *allSongs = [[NSMutableDictionary alloc] init];
    for (EPFolder *folder in root.topFolders) {
        [self addToAllSongs:allSongs folder:folder];
    }
    
    // Create a dictionary of all items used to check for deleted songs.
    MPMediaQuery *allQuery = [MPMediaQuery songsQuery];
    NSMutableDictionary *allItems = [[NSMutableDictionary alloc] init];

    // Determine the library size for the progress indicator.
    NSUInteger libSize = allQuery.items.count + allSongs.count;
    NSUInteger songsScanned = 0;
    
    // For each song not already in the database, add it.
    for (MPMediaItem *item in allQuery.items) {
        
        songsScanned += 1;
        [self performSelectorOnMainThread:@selector(importUpdateProgress:)
                               withObject:@((float)songsScanned/(float)libSize)
                            waitUntilDone:NO];

        EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:item];
        [allItems setObject:wrapper forKey:wrapper.persistentID];
        if ([allSongs objectForKey:wrapper.persistentID] == nil) {
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
                [root.playlists addEntriesObject:genreFolder];
            }
            EPFolder *genreArtist = [genreFolder folderWithName:wrapper.albumArtist];
            if (genreArtist == nil) {
                genreArtist = [EPFolder folderWithName:wrapper.albumArtist
                                             sortOrder:EPSortOrderAddDate
                                           releaseDate:[NSDate distantPast]
                                               addDate:[NSDate distantPast]
                                              playDate:[NSDate distantPast]];
                [genreFolder addEntriesObject:genreArtist];
            }
            EPFolder *genreAlbum = [genreArtist folderWithName:wrapper.albumTitle];
            if (genreAlbum == nil) {
                genreAlbum = [EPFolder folderWithName:wrapper.albumTitle
                                            sortOrder:EPSortOrderManual
                                          releaseDate:[NSDate distantPast]
                                              addDate:[NSDate distantPast]
                                             playDate:[NSDate distantPast]];
                [genreArtist addEntriesObject:genreAlbum];
            }
            [genreAlbum addEntriesObject:song];

            // Determine where it should go in artists.
            EPFolder *artistFolder = [root.artists folderWithName:wrapper.albumArtist];
            if (artistFolder == nil) {
                artistFolder = [EPFolder folderWithName:wrapper.albumArtist
                                              sortOrder:EPSortOrderAddDate
                                            releaseDate:[NSDate distantPast]
                                                addDate:[NSDate distantPast]
                                               playDate:[NSDate distantPast]];
                [root.artists addEntriesObject:artistFolder];
            }
            
            // Determine where it should go in albums.
            EPFolder *albumFolder = [root.albums folderWithName:wrapper.albumTitle];
            if (albumFolder == nil) {
                albumFolder = [EPFolder folderWithName:wrapper.albumTitle
                                             sortOrder:EPSortOrderManual
                                           releaseDate:[NSDate distantPast]
                                               addDate:[NSDate distantPast]
                                              playDate:[NSDate distantPast]];
                [root.albums addEntriesObject:albumFolder];
                // Assume album is missing in artist as well.
                [artistFolder addEntriesObject:albumFolder];
            }
            [albumFolder addEntriesObject:song];
            
            [song propagateAddDate:[NSDate date]];
            [song propagateReleaseDate:wrapper.releaseDate];
            song.playDate = [NSDate distantPast];
        }
    }
    
    // Check if any songs have been removed.
    for (NSNumber *persistentID in allSongs) {
        if ([allItems objectForKey:persistentID] == nil) {
            // Remove song.
            EPSong *song = [allSongs objectForKey:persistentID];
            [removedSongs addObjectsFromArray:[song pathNames]];
            removedSongCount += 1;
            NSSet *parentsCopy = [NSSet setWithSet:song.parents];
            for (EPFolder *parent in parentsCopy) {
                [parent removeEntriesObject:song];
                [parent removeIfEmpty];
            }
        }
        songsScanned += 1;
        [self performSelectorOnMainThread:@selector(importUpdateProgress:)
                               withObject:@((float)songsScanned/(float)libSize)
                            waitUntilDone:NO];
    }
    
    NSLog(@"Committing data.");
    [root save];
    NSLog(@"Done update scan...");
    
    // Prepare a view of what's added and removed.
    NSMutableString *results = [[NSMutableString alloc] init];
    if (addedSongs.count) {
        [results appendFormat:@"Added %i songs:\n", addedSongs.count];
        for (EPMediaItemWrapper *wrapper in addedSongs) {
            [results appendFormat:@"\t%@ - %@ - %@\n", wrapper.artist, wrapper.albumTitle, wrapper.title];
        }
    } else {
        [results appendString:@"No songs added.\n"];
    }
    if (removedSongCount) {
        [results appendFormat:@"Removed %i songs:\n", removedSongCount];
        for (NSString *path in removedSongs) {
            [results appendFormat:@"\t%@\n", path];
        }
    } else {
        [results appendString:@"No songs removed.\n"];
    }
    if (brokenItems.count) {
        [results appendFormat:@"Found %i invalid songs:\n", brokenItems.count];
        for (EPMediaItemWrapper *wrapper in brokenItems) {
            [results appendFormat:@"\t%@ - %@ - %@\n", wrapper.artist, wrapper.albumTitle, wrapper.title];
        }
    }

    [self performSelectorOnMainThread:@selector(updateDBDone:) withObject:results waitUntilDone:NO];
}

- (void)addToAllSongs:(NSMutableDictionary *)allSongs folder:(EPFolder *)folder
{
    for (EPEntry *entry in folder.entries) {
        if ([entry.class isSubclassOfClass:[EPFolder class]]) {
            [self addToAllSongs:allSongs folder:(EPFolder *)entry];
        } else {
            EPSong *song = (EPSong *)entry;
            [allSongs setObject:entry forKey:song.persistentID];
        }
    }
}

- (void)updateDBDone:(NSString *)results
{
    [self.importAlertView dismissWithClickedButtonIndex:0 animated:YES];
    [self.dbSender performSelector:@selector(dbUpdateDone:) withObject:results];
}

@end
