//
//  EPMainTabController.h
//  ePlayer
//
//  Created by Eric Huss on 4/25/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPPlaylistTableController.h"
#import "EPPlayerController.h"

@interface EPMainTabController : UITabBarController

@property (strong, nonatomic) EPPlayerController *playerController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)mainInitDataStore:(NSPersistentStoreCoordinator *)store
                    model:(NSManagedObjectModel *)model
                  context:(NSManagedObjectContext *)context;
- (void)loadInitialFolders;
- (void)resortPlayDates;

@end
