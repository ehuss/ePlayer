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
#import "NSManagedObjectModel+KCOrderedAccessorFix.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //    [[NSFileManager defaultManager] removeItemAtURL:[self dbURL] error:nil];

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
    [self.mainTabController mainInitDataStore:self.persistentStoreCoordinator
                                        model:self.managedObjectModel
                                      context:self.managedObjectContext];
    
    if ([self loadData]) {
        // Database is ready.  Populate the view.
        // XXX restore state
        [self.mainTabController loadInitialFolders];
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
/* Core Data Stack                                                           */
/*****************************************************************************/
- (NSURL *)dbURL
{
    NSURL *docDir = [[[NSFileManager defaultManager]
                      URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]
                     lastObject];
    
    NSURL *storeURL = [docDir URLByAppendingPathComponent:@"ePlayer.sqlite"];
    return storeURL;
}

- (NSManagedObjectModel *)createManagedObjectModel
{
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
    [model kc_generateOrderedSetAccessors];
    return model;
}


- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [self createManagedObjectModel];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)createPersistentStoreCoordinator:(NSManagedObjectModel *)model
{
    NSError *error;
    NSPersistentStoreCoordinator *coordinator;
    coordinator = [[NSPersistentStoreCoordinator alloc]
                   initWithManagedObjectModel:model];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                   configuration:nil
                                             URL:[self dbURL]
                                         options:nil
                                           error:&error]) {
        NSLog(@"Error: %@", [error localizedDescription]);
        return nil;
    }
    return coordinator;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    _persistentStoreCoordinator = [self createPersistentStoreCoordinator:self.managedObjectModel];
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *) createManagedObjectContext:(NSPersistentStoreCoordinator *)coordinator
{
    NSManagedObjectContext *context = nil;
    // May be nil if fails to load.
    if (coordinator != nil) {
        context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = coordinator;
    }
    return context;
}

- (NSManagedObjectContext *) managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    _managedObjectContext = [self createManagedObjectContext:self.persistentStoreCoordinator];
    return _managedObjectContext;
}

/*****************************************************************************/
/* Data Importing                                                            */
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
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entry"
                                              inManagedObjectContext:self.managedObjectContext];
    request.entity = entity;
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (results == nil) {
        NSLog(@"Failed to query for entries: %@", error);
        // This should probably be a fatal error.
        return YES;
    }
    NSLog(@"query length: %i", results.count);
    
    if (results.count == 0) {
        // Database is empty, running for the first time.
        // Populate with defaults from the user's library.
        // Display a progress indicator.
        self.importAlertView = [[UIAlertView alloc] initWithTitle:@"Importing..." message:@"Performing first time import." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
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
    } else {
        return YES;
    }
}

- (void)initDB
{
    /* Things to consider for efficiency:
     use autorelease pool block?
     context refreshObject: mergeChanges:NO to unload objects when done (like artist)
     Is there maybe a way to append to "entries" using something more lightweight, like objectID?
     */
    NSError *error;
    // Using a thread-local context (was having problems otherwise, even though
    // nothing should be happening on the main thread).
    // Note: Could probably share the coordinator with the main thread.
//    NSManagedObjectContext *managedObjectContext = [self createManagedObjectContext:
//                                                    [self createPersistentStoreCoordinator:
//                                                     [self createManagedObjectModel]]];
    NSManagedObjectContext *managedObjectContext = [self createManagedObjectContext:self.persistentStoreCoordinator];
    // This doesn't seem to make a noticeable performance improvement.
    managedObjectContext.undoManager = nil;
    
    // Determine the library size for the progress indicator.
    MPMediaQuery *allQuery = [MPMediaQuery songsQuery];
    NSUInteger libSize = allQuery.items.count;
    NSUInteger songsImported = 0;
    
    // Create top-level folder.
    Folder *rootFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                inManagedObjectContext:managedObjectContext];
    rootFolder.name = @"Playlists";
    rootFolder.sortOrder = @(EPSortOrderAlpha);
    rootFolder.addDate = [NSDate date];
    rootFolder.releaseDate = [NSDate distantPast];
    rootFolder.playDate = [NSDate distantPast];
    
    Folder *artistsFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                    inManagedObjectContext:managedObjectContext];
    artistsFolder.name = @"Artists";
    artistsFolder.sortOrder = @(EPSortOrderAlpha);
    artistsFolder.addDate = [NSDate date];
    artistsFolder.releaseDate = [NSDate distantPast];
    artistsFolder.playDate = [NSDate distantPast];

    Folder *albumsFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                    inManagedObjectContext:managedObjectContext];
    albumsFolder.name = @"Albums";
    albumsFolder.sortOrder = @(EPSortOrderAlpha);
    albumsFolder.addDate = [NSDate date];
    albumsFolder.releaseDate = [NSDate distantPast];
    albumsFolder.playDate = [NSDate distantPast];

    // Create a magic folder used for "cut".
    Folder *cutFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                  inManagedObjectContext:managedObjectContext];
    cutFolder.name = @"Internal Cut Folder";
    cutFolder.sortOrder = @(EPSortOrderManual);
    // These dates are unused, but are required.
    cutFolder.addDate = [NSDate date];
    cutFolder.releaseDate = [NSDate distantPast];
    cutFolder.playDate = [NSDate distantPast];

    
    // Create a magic folder used by the queue.
    Folder *queueFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                 inManagedObjectContext:managedObjectContext];
    queueFolder.name = @"Queue";
    queueFolder.sortOrder = @(EPSortOrderManual);
    // These dates are unused, but are required.
    queueFolder.addDate = [NSDate date];
    queueFolder.releaseDate = [NSDate distantPast];
    queueFolder.playDate = [NSDate distantPast];
    
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
        Folder *genreFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                      inManagedObjectContext:managedObjectContext];
        genreFolder.name = [representativeItem valueForProperty:MPMediaItemPropertyGenre];
        genreFolder.sortOrder = @(EPSortOrderAddDate);//[NSNumber numberWithInt:];
        // These dates will be updated once songs are seen.
        genreFolder.addDate = [NSDate distantPast];
        genreFolder.releaseDate = [NSDate distantPast];
        genreFolder.playDate = [NSDate distantPast];
        [rootFolder addEntriesObject:genreFolder];
        [genres setObject:genreFolder forKey:genreFolder.name];
    }
    
    // Fetch all albums.
    MPMediaQuery *albums = [MPMediaQuery albumsQuery];
    // Keep a unique set of artists.
    NSMutableDictionary *artists = [[NSMutableDictionary alloc] init];
    for (MPMediaItemCollection *albumItem in albums.collections) {
        MPMediaItem *representativeItem = albumItem.representativeItem;
        // XXX: What if genre is nil?
        Folder *genre = [genres objectForKey:[representativeItem valueForProperty:MPMediaItemPropertyGenre]];
        NSString *artistName = artistNameFromMediaItem(representativeItem);
        if (artistName == nil) {
            continue;
        }
        
        // Create artist if it does not exist.
        Folder *artist = [artists objectForKey:artistName];
        if (artist == nil) {
            // Create artist folder.
            artist = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                             inManagedObjectContext:managedObjectContext];
            artist.name = artistName;
            artist.sortOrder = @(EPSortOrderAddDate);
            // These dates will be updated once songs are seen.
            artist.addDate = [NSDate distantPast];
            artist.releaseDate = [NSDate distantPast];
            artist.playDate = [NSDate distantPast];
            [artists setObject:artist forKey:artistName];
            [genre addEntriesObject:artist];
            [artistsFolder addEntriesObject:artist];
            NSLog(@"Create artist %@", artist.name);
        }
        
        // Create album folder.
        Folder *albumFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                inManagedObjectContext:managedObjectContext];
        albumFolder.name = [representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle];
        albumFolder.sortOrder = @(EPSortOrderManual);
        // These dates will be updated once songs are seen.
        albumFolder.addDate = [NSDate distantPast];
        albumFolder.releaseDate = [NSDate distantPast];
        albumFolder.playDate = [NSDate distantPast];
        [artist addEntriesObject:albumFolder];
        [albumsFolder addEntriesObject:albumFolder];
        NSLog(@"Create album %@", albumFolder.name);
        
        // Add songs to album folder.
        NSUInteger maxPlayCount = 0;
        for (MPMediaItem *songItem in albumItem.items) {
            EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:songItem];
            Song *song = (Song *)[NSEntityDescription insertNewObjectForEntityForName:@"Song"
                                                               inManagedObjectContext:managedObjectContext];
            song.name = wrapper.title;
            song.persistentID = wrapper.persistentID;
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
            song.playCount = wrapper.playCount;
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
    if (![managedObjectContext save:&error]) {
        NSLog(@"Failed to save: %@", error);
    }
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
}

@end
