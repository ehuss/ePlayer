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

@interface EPPlaylistTableController : EPBrowseTableController <UIActionSheetDelegate>
{
    Folder *_cutFolder;
}

- (void)loadRootFolder;
- (EPPlaylistTableController *)copyMusicController;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) Folder *folder;
@property (nonatomic, readonly) Folder *cutFolder;

@end
