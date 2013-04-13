//
//  EPEntryTableController.h
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Models/EPModels.h"

@interface EPPlaylistTableController : UITableViewController

- (void)loadRootFolder;
- (EPPlaylistTableController *)copyMusicController;

@property (nonatomic) BOOL enabled;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) Folder *folder;
@property (nonatomic, strong) NSArray *sortedEntries;
@end
