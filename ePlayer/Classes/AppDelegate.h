//
//  AppDelegate.h
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPMainTabController.h"
#import "EPPlayerController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

- (BOOL)loadData;
- (NSURL *)dbURL;
- (void)initDB;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EPMainTabController *mainTabController;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) UIAlertView *importAlertView;
@property (strong, nonatomic) UIProgressView *importProgressView;

@end
