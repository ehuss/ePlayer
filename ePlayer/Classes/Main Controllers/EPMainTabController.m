//
//  EPMainTabController.m
//  ePlayer
//
//  Created by Eric Huss on 4/25/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPMainTabController.h"
#import "EPRoot.h"

@implementation EPMainTabController

- (void)mainInit
{
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
}

- (void)loadInitialFolders
{
    EPPlaylistTableController *cont;
    EPRoot *root = [EPRoot sharedRoot];
    cont = (EPPlaylistTableController *)((UINavigationController *)self.viewControllers[0]).topViewController;
    cont.folder = root.playlists;
    [cont.tableView reloadData];

    cont = (EPPlaylistTableController *)((UINavigationController *)self.viewControllers[1]).topViewController;
    cont.folder = root.artists;
    [cont.tableView reloadData];

    cont = (EPPlaylistTableController *)((UINavigationController *)self.viewControllers[2]).topViewController;
    cont.folder = root.albums;
    [cont.tableView reloadData];
}

- (void)resortPlayDates
{
    for (UIViewController *controller in self.viewControllers) {
        if ([controller.class isSubclassOfClass:[UINavigationController class]]) {
            UINavigationController *navCont = (UINavigationController *)controller;
            for (EPPlaylistTableController *playlistCont in navCont.viewControllers) {
                if (playlistCont.sortOrder == EPSortOrderPlayDate) {
                    [playlistCont updateSections];
                    [playlistCont.tableView reloadData];
                }
            }
        }
    }
}


@end
