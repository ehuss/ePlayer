//
//  EPEntryTableController.h
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPCommon.h"
#import "EPBrowseTableController.h"
#import "EPEditCell1.h"
#import "EPEditCell2.h"
#import "EPRoot.h"

@interface EPPlaylistTableController : EPBrowseTableController <UIActionSheetDelegate>
{
    EPRoot *_root;
}

- (EPPlaylistTableController *)copyMusicController;
- (void)updateSections;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) EPFolder *folder;
@property (nonatomic, readonly) EPRoot *root;
@property (nonatomic, assign) BOOL focusAddFolder;
@property (nonatomic, strong) EPEditCell1 *editCell1;
@property (nonatomic, strong) EPEditCell2 *editCell2;

@end
