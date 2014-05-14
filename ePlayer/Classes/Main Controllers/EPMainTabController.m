//
//  EPMainTabController.m
//  ePlayer
//
//  Created by Eric Huss on 4/25/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPMainTabController.h"
#import "EPBrowseTableController.h"
#import "EPRoot.h"

@implementation EPMainTabController

- (void)awakeFromNib
{
    self.delegate = self;
}

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
    EPBrowseTableController *cont;
    EPRoot *root = [EPRoot sharedRoot];
    cont = (EPBrowseTableController *)((UINavigationController *)self.viewControllers[0]).topViewController;
    cont.folder = root.playlists;
    [cont.tableView reloadData];

    cont = (EPBrowseTableController *)((UINavigationController *)self.viewControllers[1]).topViewController;
    cont.folder = root.artists;
    [cont.tableView reloadData];

    cont = (EPBrowseTableController *)((UINavigationController *)self.viewControllers[2]).topViewController;
    cont.folder = root.albums;
    [cont.tableView reloadData];
}

- (void)reloadBrowsers
{
    for (UIViewController *controller in self.viewControllers) {
        if ([controller.class isSubclassOfClass:[UINavigationController class]]) {
            UINavigationController *navCont = (UINavigationController *)controller;
            for (EPBrowseTableController *browseCont in navCont.viewControllers) {
                if ([browseCont.class isSubclassOfClass:[EPBrowseTableController class]]) {
                    // XXX Why did I have this?
//                    if (browseCont.sortOrder == EPSortOrderPlayDate) {
                        [browseCont updateSections];
                        [browseCont.tableView reloadData];
//                    }
                }
            }
        }
    }
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    // Don't set if you click on a tab twice.
    if (self.selectedViewController != selectedViewController) {
        self.previousController = self.selectedViewController;
    }
    [super setSelectedViewController:selectedViewController];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    // This does not work with "More" navigation.
    UIViewController *selectedViewController = self.viewControllers[selectedIndex];
    // Don't set if you click on a tab twice.
    if (self.selectedViewController != selectedViewController) {
        self.previousController = self.selectedViewController;
    }
    // I'm assuming that when you set the index, setSelectedViewController is
    // not called, which seems to be the case.
    [super setSelectedIndex:selectedIndex];
}

//- (BOOL)tabBarController:(UITabBarController *)tabBarController
//shouldSelectViewController:(UIViewController *)viewController
//{
//    // Don't set if you click on a tab twice.
//    if (self.selectedViewController != viewController) {
//        self.previousController = self.selectedViewController;
//    }
//    return YES;
//}


@end
