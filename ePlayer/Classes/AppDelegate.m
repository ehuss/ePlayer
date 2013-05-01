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
/* Misc                                                                      */
/*****************************************************************************/


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
    // Display a progress indicator.
    self.importAlertView = [[UIAlertView alloc] initWithTitle:@"Importing..."
                                                      message:@"Performing first time import."
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:nil];
    [self.importAlertView show];
    self.importProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    // This is rather hacky.  The alertView frame is an odd size (presumably
    // for all the shadowing).  It's unfortunate that UIAlertView does not
    // have a formal way to add accessory views.
    // The Right Thing to do would be to make a custom view.
    CGRect avf = self.importAlertView.frame;
    CGRect pvf = self.importProgressView.frame;
    self.importProgressView.frame = CGRectMake(20, avf.size.height-pvf.size.height-50,
                                    avf.size.width-70, pvf.size.height);
    
    [self.importAlertView addSubview:self.importProgressView];
    [self performSelectorInBackground:@selector(initDB) withObject:nil];
    return NO;
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
            [genre addEntriesObject:artist];
            [root.artists addEntriesObject:artist];
            NSLog(@"Create artist %@", artist.name);
        }
        
        // Create album folder.
        // These dates will be updated once songs are seen.
        EPFolder *albumFolder = [EPFolder folderWithName:[representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle]
                                               sortOrder:EPSortOrderManual
                                             releaseDate:[NSDate distantPast]
                                                 addDate:[NSDate distantPast]
                                                playDate:[NSDate distantPast]];
        [artist addEntriesObject:albumFolder];
        [root.albums addEntriesObject:albumFolder];
        NSLog(@"Create album %@", albumFolder.name);
        
        // Add songs to album folder.
        NSUInteger maxPlayCount = 0;
        for (MPMediaItem *songItem in albumItem.items) {
            EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:songItem];
            EPSong *song = [EPSong songWithName:wrapper.title
                                   persistentID:wrapper.persistentID];
            [albumFolder addEntriesObject:song];
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

@end
