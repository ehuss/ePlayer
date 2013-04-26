//
//  EPMainTabController.m
//  ePlayer
//
//  Created by Eric Huss on 4/25/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPMainTabController.h"

@implementation EPMainTabController

- (void)mainInitDataStore:(NSPersistentStoreCoordinator *)store
                    model:(NSManagedObjectModel *)model
                  context:(NSManagedObjectContext *)context
{
    self.persistentStoreCoordinator = store;
    self.managedObjectModel = model;
    self.managedObjectContext = context;
    UIStoryboard *sboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];
    // Create the 3 main playlist viewers and add them as tabs.
    NSMutableArray *controllers = [NSMutableArray arrayWithCapacity:4];
    
    UINavigationController *navCont = [sboard instantiateViewControllerWithIdentifier:@"PlaylistNavController"];
    [controllers addObject:navCont];
    navCont.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Playlists"
                                                       image:nil tag:0];
    
    navCont = [sboard instantiateViewControllerWithIdentifier:@"PlaylistNavController"];
    [controllers addObject:navCont];
    navCont.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Artists"
                                                       image:nil tag:0];
    
    navCont = [sboard instantiateViewControllerWithIdentifier:@"PlaylistNavController"];
    [controllers addObject:navCont];
    navCont.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Albums"
                                                       image:nil tag:0];
    
    // Get the queue/player and add as a tab.
    self.playerController = [sboard instantiateViewControllerWithIdentifier:@"PlayerScene"];
    [controllers addObject:self.playerController];
    
    self.viewControllers = controllers;

    for (UIViewController *controller in self.viewControllers) {
        UIViewController *actualCont = controller;
        if ([controller.class isSubclassOfClass:[UINavigationController class]]) {
            actualCont = ((UINavigationController *)controller).topViewController;
        }
        if ([actualCont respondsToSelector:@selector(setPersistentStoreCoordinator:)]) {
            [actualCont performSelector:@selector(setPersistentStoreCoordinator:) withObject:store];
            [actualCont performSelector:@selector(setManagedObjectModel:) withObject:model];
            [actualCont performSelector:@selector(setManagedObjectContext:) withObject:context];
        }
    }
}

- (void)loadInitialFolders
{
    [(EPPlaylistTableController *)((UINavigationController *)self.viewControllers[0]).topViewController loadInitialFolderTemplate:@"RootFolder"];
    [(EPPlaylistTableController *)((UINavigationController *)self.viewControllers[1]).topViewController loadInitialFolderTemplate:@"ArtistFolder"];
    [(EPPlaylistTableController *)((UINavigationController *)self.viewControllers[2]).topViewController loadInitialFolderTemplate:@"AlbumFolder"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
