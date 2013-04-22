//
//  AppDelegate.m
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"
#import "EPCommon.h"
#import "EPArtistTableController.h"
#import "EPAlbumTableController.h"
#import "EPSortOrderController.h"
#import "EPMediaItemWrapper.h"
#import "NSManagedObjectModel+KCOrderedAccessorFix.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    createGregorianCalendar();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{EPSettingArtistsSortOrder: [NSNumber numberWithInt:EPSortOrderAlpha],
                                 EPSettingAllAbumsSortOrder: [NSNumber numberWithInt:EPSortOrderReleaseDate],
                                 EPSettingArtistAlbumsSortOrder: [NSNumber numberWithInt:EPSortOrderReleaseDate]}];
    playlistPasteboard = [UIPasteboard pasteboardWithName:@"org.ehuss.ePlayer" create:YES];
    playlistPasteboard.persistent = YES;
//    MPMediaQuery *artists = [[MPMediaQuery alloc] init];
//    [artists setGroupingType:MPMediaGroupingAlbumArtist];
//    for (MPMediaItemCollection *artist in artists.collections) {
//        MPMediaItem *item = [artist representativeItem];
//        NSLog(@"%@ %@", [item valueForProperty:MPMediaItemPropertyArtist],
//              [item valueForProperty:MPMediaItemPropertyAlbumArtist]);
//    }
//    return YES;

    
    /*
    MPMediaQuery *everything2 = [[MPMediaQuery alloc] init];
    NSLog(@"Total: %i", everything2.items.count);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (MPMediaItem *song in everything2.items) {
        [dict setObject:song forKey:[song valueForProperty:MPMediaItemPropertyPersistentID]];
    }
    NSMutableDictionary *dict2 = [[NSMutableDictionary alloc] init];
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    [everything setGroupingType:MPMediaGroupingAlbumArtist];
    NSArray *artists = [everything collections];
    NSLog(@"Album artist count %i", artists.count);
    [everything setGroupingType:MPMediaGroupingArtist];
    NSArray *artists2 = [everything collections];
    NSLog(@"Artist count %i", artists2.count);
    uint count = 0;
    for (MPMediaItemCollection *artist in artists) {
        MPMediaItem *representativeItem = [artist representativeItem];
        NSString *artistName = [representativeItem valueForProperty:MPMediaItemPropertyAlbumArtist];
        NSString *albumName = [representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle];
        NSLog(@"%@ by %@ (%i songs)", albumName, artistName, album.items.count);
        for (MPMediaItem *song in album.items) {
            NSLog(@"    %@", [song valueForProperty:MPMediaItemPropertyTitle]);
            count += 1;
            [dict2 setObject:song forKey:[song valueForProperty:MPMediaItemPropertyPersistentID]];
        }
    }
    NSLog(@"Found %i", count);
    NSSet *x = [dict keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return [dict2 objectForKey:key] == nil;
    }];
    for (NSString *key in x) {
        MPMediaItem *e = [dict objectForKey:key];
        NSLog(@"not in album: %@", [e valueForProperty:MPMediaItemPropertyTitle]);
    }*/
//    [[NSFileManager defaultManager] removeItemAtURL:[self dbURL] error:nil];
    
    self.tabController = (UITabBarController *)self.window.rootViewController;
    self.tabController.delegate = self;
    self.playlistNavController = self.tabController.viewControllers[0];
    self.playlistTableController = (EPPlaylistTableController *)self.playlistNavController.topViewController;
    self.playlistTableController.managedObjectContext = self.managedObjectContext;
    self.playlistTableController.managedObjectModel = self.managedObjectModel;
    self.playlistTableController.persistentStoreCoordinator = self.persistentStoreCoordinator;
        
    if ([self loadData]) {
        // Database is ready.  Populate the view.
        // XXX restore state
        [self.playlistTableController loadRootFolder];
    } else {
        // Database import happens in background.
        // Don't display anything until it is done.
    }

    self.playerController = self.tabController.viewControllers[3];
    self.playerController.managedObjectContext = self.managedObjectContext;
    self.playerController.managedObjectModel = self.managedObjectModel;
    [self.playerController loadCurrentQueue];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    rootFolder.sortOrder = @(EPSortOrderAlpha);//[NSNumber numberWithInt:EPSortOrderAlpha];
    rootFolder.addDate = [NSDate date];
    rootFolder.releaseDate = [NSDate distantPast];
    rootFolder.playDate = [NSDate distantPast];
    
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
    MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic) forProperty:MPMediaItemPropertyMediaType];
    [genreQuery addFilterPredicate:pred];
    // Keep track of genre folders for later.
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
        // Get all albums in this genre.
        // (Using albums because AlbumArtist isn't always there, and Artist
        // isn't always what I want.)
        MPMediaQuery *albums = [MPMediaQuery albumsQuery];
        MPMediaPredicate *gPred = [MPMediaPropertyPredicate
                                   predicateWithValue:[representativeItem valueForProperty:MPMediaItemPropertyGenrePersistentID]
                                   forProperty:MPMediaItemPropertyGenrePersistentID];
        [albums addFilterPredicate:gPred];
        // Create a unique set of artists.  Value is a representative song.
        NSMutableDictionary *artists = [[NSMutableDictionary alloc] init];
        for (MPMediaItemCollection *album in albums.collections) {
            MPMediaItem *representativeItem2 = album.representativeItem;
            NSString *artistName = artistNameFromMediaItem(representativeItem2);
            if (artistName == nil) {
                continue;
            }
            [artists setObject:representativeItem2 forKey:artistName];
        }
        // Create artist folders.
        NSMutableDictionary *artistFolders = [[NSMutableDictionary alloc] init];
        for (MPMediaItem *item in artists.objectEnumerator) {
            NSString *artistName = artistNameFromMediaItem(item);
            NSLog(@"Creating artist %@.", artistName);
            Folder *artistFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                           inManagedObjectContext:managedObjectContext];
            artistFolder.name = artistName;
            artistFolder.sortOrder = @(EPSortOrderAddDate);//[NSNumber numberWithInt:];
            // These dates will be updated once songs are seen.
            artistFolder.addDate = [NSDate distantPast];
            artistFolder.releaseDate = [NSDate distantPast];
            artistFolder.playDate = [NSDate distantPast];
            [artistFolders setObject:artistFolder forKey:artistName];
            Folder *genre = [genres objectForKey:[item valueForProperty:MPMediaItemPropertyGenre]];
            // XXX: Can genre be nil/empty with a group-by with genre?
            // If so, lazily create an "Unknown" genre folder.
            [genre addEntriesObject:artistFolder];
        }
        NSLog(@"Create album folders.");
        // Iterate over albums again, inserting album folders.
        uint albumCount = 0;
        for (MPMediaItemCollection *album in albums.collections) {
            MPMediaItem *representativeItem2 = album.representativeItem;
            // Create album folder.
            Folder *albumFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                          inManagedObjectContext:managedObjectContext];
            albumFolder.name = [representativeItem2 valueForProperty:MPMediaItemPropertyAlbumTitle];
            albumFolder.sortOrder = @(EPSortOrderManual);
            // These dates will be updated once songs are seen.
            albumFolder.addDate = [NSDate distantPast];
            albumFolder.releaseDate = [NSDate distantPast];
            albumFolder.playDate = [NSDate distantPast];
            NSString *artistName = artistNameFromMediaItem(representativeItem2);
            Folder *artistFolder = [artistFolders objectForKey:artistName];
            [artistFolder addEntriesObject:albumFolder];
            // Insert all songs into album folder.
            NSLog(@"Iterating over songs in album %@.", albumFolder.name);
            for (MPMediaItem *songItem in album.items) {
                EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:songItem];
                Song *song = (Song *)[NSEntityDescription insertNewObjectForEntityForName:@"Song"
                                                                   inManagedObjectContext:managedObjectContext];
                song.name = wrapper.title;
                song.persistentID = wrapper.persistentID;
                [albumFolder addEntriesObject:song];
                NSDate *date;

                date = wrapper.releaseDate;
                [song propagateReleaseDate:date];

                date = wrapper.lastPlayedDate;
                if (date == nil) {
                    date = [NSDate distantPast];
                }
                [song propagatePlayDate:date];
                [song propagateAddDate:song.releaseDate];
                NSNumber *playCount = wrapper.playCount;
                if (playCount != nil) {
                    [song propagatePlayCount:playCount];
                }
                songsImported += 1;
            }
            [self performSelectorOnMainThread:@selector(importUpdateProgress:)
                                   withObject:@((float)songsImported/(float)libSize)
                                waitUntilDone:NO];
            albumCount += 1;
#ifdef EP_MEMORY_DEBUG
            logMemUsage();
#endif
        }
        
    }
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
    [self.playlistTableController loadRootFolder];
}

/*****************************************************************************/
/* Tab Bar Methods                                                           */
/*****************************************************************************/
- (BOOL)tabBarController:(UITabBarController *)tabBarController
 shouldSelectViewController:(UIViewController *)viewController
{
    if (![tabBarController.selectedViewController.class isSubclassOfClass:[EPSortOrderController class]]) {
        if ([viewController.class isSubclassOfClass:[EPSortOrderController class]]) {
            // Selecting sort order.
            // Tell the sort order controller what the current sort order is.
            UINavigationController *navCont = (UINavigationController *)tabBarController.selectedViewController;
            EPBrowseTableController *browse = (EPBrowseTableController *)navCont.topViewController;
            EPSortOrderController *controller = (EPSortOrderController *)viewController;
            controller.currentSortOrder = browse.sortOrder;
            controller.previousControllerIndex = tabBarController.selectedIndex;
        }
    }
    return YES;
}

@end
