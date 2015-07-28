//
//  EPMainTabController.h
//  ePlayer
//
//  Created by Eric Huss on 4/25/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPPlayerController.h"

@interface EPMainTabController : UITabBarController <UITabBarControllerDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) EPPlayerController *playerController;
@property (nonatomic) UIViewController *previousController;

- (void)mainInit;
- (void)loadInitialFolders;
- (void)reloadBrowsers;
- (void)resetBrowsers;

@end
