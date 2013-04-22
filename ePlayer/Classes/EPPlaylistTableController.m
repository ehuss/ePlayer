//
//  EPEntryTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "EPPlaylistTableController.h"
#import "EPCommon.h"
#import "EPPlayerController.h"

static NSString *kEPOrphanFolderName = @"Orphaned Songs";
//static NSString *kEPEntryUTI = @"org.ehuss.ePlayer.entry";

@interface EPPlaylistTableController ()

@end

@implementation EPPlaylistTableController


- (EPPlaylistTableController *)copyMusicController
{
    EPPlaylistTableController *controller = [[EPPlaylistTableController alloc] initWithStyle:UITableViewStylePlain];
    controller.managedObjectContext = self.managedObjectContext;
    controller.managedObjectModel = self.managedObjectModel;
    controller.persistentStoreCoordinator = self.persistentStoreCoordinator;
    controller.tableView.allowsMultipleSelectionDuringEditing = YES;
    return controller;
}

- (void)setSortOrder:(EPSortOrder)sortOrder
{
    self.folder.sortOrder = [NSNumber numberWithInt:sortOrder];
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Failed to save: %@", error);
    }
    [self updateSections];
    [self.tableView reloadData];
}

- (EPSortOrder)sortOrder
{
    return [self.folder.sortOrder intValue];
}

- (NSArray *)supportedSortOrders
{
    return @[@(EPSortOrderAlpha),
             @(EPSortOrderAddDate),
             @(EPSortOrderPlayDate),
             @(EPSortOrderReleaseDate),
             @(EPSortOrderManual)];
}

- (NSArray *)controlCells
{
    if (_controlCells == nil) {
        _controlCells = @[[self createSortOrderCell],
                          [self createInsertCell],
                          [self createEditCell]];
    }
    return _controlCells;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (UITableViewCell *)createInsertCell
{
    NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"InsertCell"
                                                      owner:self
                                                    options:nil];
    UITableViewCell *cell = nibViews[0];
    UITextField *text = (UITextField *)[cell viewWithTag:1];
    text.delegate = self;
    return cell;
}

- (UITableViewCell *)createEditCell
{
    NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"EditCell"
                                                      owner:self
                                                    options:nil];
    UITableViewCell *cell = nibViews[0];
    UIButton *deleteButton = (UIButton *)[cell viewWithTag:1];
    UIButton *cutButton = (UIButton *)[cell viewWithTag:2];
    UIButton *copyButton = (UIButton *)[cell viewWithTag:3];
    UIButton *pasteButton = (UIButton *)[cell viewWithTag:4];
    UIButton *renameButton = (UIButton *)[cell viewWithTag:5];
    [deleteButton addTarget:self action:@selector(delete:)
           forControlEvents:UIControlEventTouchUpInside];
    [cutButton addTarget:self action:@selector(cut:)
        forControlEvents:UIControlEventTouchUpInside];
    [copyButton addTarget:self action:@selector(copy:)
         forControlEvents:UIControlEventTouchUpInside];
    [pasteButton addTarget:self action:@selector(paste:)
          forControlEvents:UIControlEventTouchUpInside];
    [renameButton addTarget:self action:@selector(rename:)
           forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (NSString *)filterPropertyName
{
    return @"name";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*****************************************************************************/
/* Table Data Source                                                         */
/*****************************************************************************/
#pragma mark - Table view data source

// Populates the labels for a cell with the values for an entry.
- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel
{
    Entry *entry = sections[indexPath.section][indexPath.row];
    cell.textView.text = entry.name;
    if ([entry.class isSubclassOfClass:[Folder class]]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if (useDateLabel) {
        cell.dateLabel.text = [self.folder sectionTitleForEntry:entry];
    }    
}


/*****************************************************************************/
/* Action Methods                                                            */
/*****************************************************************************/

- (void)playTapped:(UITapGestureRecognizer *)gesture
{
    // Determine which entry was tapped.
    UITableViewCell *cell = (UITableViewCell *)[[[gesture view] superview] superview];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForCell:cell];
    Entry *entry = self.sections[tappedIndexPath.section][tappedIndexPath.row];
    // Stop whatever is playing.
    //[playerController clearQueue];
    // Add all of these items to the queue.
    NSMutableArray *newItems = [NSMutableArray arrayWithCapacity:100];
    [self addEntry:entry toArray:newItems];
    // Add these items to the queue, start playback, and display the player.
    // Guard against playing an empty folder (which would cause an exception
    // when creating the MPMediaItemCollection).
    if (newItems.count) {
        [self.playerController clearQueue];
        [self.playerController addQueueItems:newItems];
        [self.playerController play];
        [self.navigationController pushViewController:self.playerController animated:YES];
    }
}

- (void)addEntry:(Entry *)entry toArray:(NSMutableArray *)array
{
    if ([entry isKindOfClass:[Folder class]]) {
        Folder *folder = (Folder *)entry;
        for (Entry *child in folder.sortedEntries) {
            [self addEntry:child toArray:array];
        }
    } else {
        // is Song type.
        [self addSong:(Song *)entry toArray:array];
    }
}

- (void)addSong:(Song *)song toArray:(NSMutableArray *)array
{
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate
                                      predicateWithValue:song.persistentID
                                      forProperty:MPMediaItemPropertyPersistentID];
    [query addFilterPredicate:pred];
    NSArray *result = query.items;
    if (result.count) {
        [array addObject:result[0]];
    } else {
        NSLog(@"Failed to fetch MPMediaItem for persistent ID song %@.", song.persistentID);
    }
}

/*****************************************************************************/
/* Table Delegate                                                            */
/*****************************************************************************/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        return;
    }
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSections;
    } else {
        data = self.sections;
    }
    Entry *entry = data[indexPath.section][indexPath.row];
    if ([entry isKindOfClass:[Folder class]]) {
        EPPlaylistTableController *controller = [self copyMusicController];
        controller.folder = (Folder *)entry;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)loadRootFolder
{
    NSFetchRequest *request = [self.managedObjectModel fetchRequestTemplateForName:@"RootFolder"];
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (results==nil || results.count==0) {
        NSLog(@"Failed to fetch root folder: %@", error);
        return;
    }
    self.folder = results[0];
    // This is necessary for the initial import which displays an empty table
    // (and possibly other things).
    [self.tableView reloadData];
}


- (void)setFolder:(Folder *)folder
{
    _folder = folder;
    self.title = folder.name;
    // Set up sections.
    [self updateSections];
}

- (void)updateSections
{
    NSArray *sortedEntries = [self.folder sortedEntries];
    // With a small number of entries, sections are a pain.
    if (self.sortOrder!=EPSortOrderManual &&
            sortedEntries.count > minEntriesForSections) {
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        self.sections = sections;
        self.sectionTitles = [[NSMutableArray alloc] init];
        NSMutableArray *currentSection = nil;
        NSString *currentSectionTitle = nil;
        for (Entry *entry in sortedEntries) {
            NSString *sectionTitle = [self.folder sectionTitleForEntry:entry];
            // Is this entry a new section?
            if (currentSection == nil || [sectionTitle compare:currentSectionTitle]!=NSOrderedSame) {
                currentSectionTitle = sectionTitle;
                [self.sectionTitles addObject:sectionTitle];
                currentSection = [[NSMutableArray alloc] init];
                [sections addObject:currentSection];
            }
            [currentSection addObject:entry];
        }
    } else {
        self.sections = [NSMutableArray arrayWithObject:
                         [NSMutableArray arrayWithArray:sortedEntries]];
        self.sectionTitles = [NSMutableArray arrayWithObject:@""];
    }
}

/*****************************************************************************/
/* Editting Support                                                          */
/*****************************************************************************/
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    if (editing) {
        self.showingControlCells = YES;
        self.indexesEnabled = NO;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        if (self.showingControlCells) {
            // Save any changes made.
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Failed to save: %@", error);
            }
            // Clean up.
            self.showingControlCells = NO;
            self.indexesEnabled = YES;
            // Would like to have this animated, but a bulk reload of the data
            // prevents that.  Something like NSFetchedResultsController would
            // probably work better.
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            // Re-sort in case anything was added.
            [self updateSections];
            [self.tableView reloadData];
        }
    }
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(editingStyle) {
        case UITableViewCellEditingStyleDelete: {
            // XXX: This is no longer supported.
            break;
        }
            
        case UITableViewCellEditingStyleInsert: {
            // XXX: This is no longer supported.
            // User clicked the green plus sign on the "add row".
            // Force the keyboard to show.
            UITableViewCell *sourceCell = [tableView cellForRowAtIndexPath:indexPath];
            UIView *textField = [sourceCell viewWithTag:1];
            [textField becomeFirstResponder];
        }
            
            break;
        case UITableViewCellEditingStyleNone:
            break;
    }
}

- (void)reloadParents
{
    // Tell any table controllers higher in the chain to reload, just in case
    // anything changed (dates, etc.).
    for (int i=0; i<self.navigationController.viewControllers.count-1; i++) {
        EPPlaylistTableController *controller = self.navigationController.viewControllers[0];
        [controller updateSections];
        [controller.tableView reloadData];
    }
}

- (void)deleteRows:(NSArray *)indexPaths checkOrphans:(BOOL)doCheckOrphans
{
    // Determine the entries to delete.
    NSMutableOrderedSet *entrySet = [NSMutableOrderedSet orderedSetWithCapacity:indexPaths.count];
    // Remove from sections.  I'm not sure if indexPaths is guaranteed to be
    // grouped by sections.  We need a set of indicies per section.
    // Key is NSNumber section number, value is NSIndexSet.
    NSMutableDictionary *toDelete = [NSMutableDictionary dictionaryWithCapacity:indexPaths.count];
    for (NSIndexPath *path in indexPaths) {
        // Adjust index for the 2 special rows if necessary.
        NSIndexPath *realIndexPath = [NSIndexPath indexPathForRow:path.row inSection:path.section-1];
        // Figure out the entry being removed.
        Entry *entry = self.sections[realIndexPath.section][realIndexPath.row];
        NSLog(@"Deleting %@", entry.name);
        [entrySet addObject:entry];
        // Add to the set of section data to clean up.
        NSNumber *sectionNumber = [NSNumber numberWithInteger:realIndexPath.section];
        NSMutableIndexSet *indexSet = [toDelete objectForKey:sectionNumber];
        if (indexSet == nil) {
            indexSet = [[NSMutableIndexSet alloc] init];
            [toDelete setObject:indexSet forKey:sectionNumber];
        }
        [indexSet addIndex:realIndexPath.row];
    }
    [self.folder removeEntries:entrySet];
    // Will be committed when editing is done.

    if (doCheckOrphans) {
        for (Entry *entry in entrySet) {
            // If any songs in this entry have no parents, put it into a special
            // orphan folder.  Otherwise there would be no way to ever access them.
            [self checkOrphans:entry];
        }
    }

    [toDelete enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSMutableIndexSet *obj, BOOL *stop) {
        NSMutableArray *section = self.sections[key.integerValue];
        [section removeObjectsAtIndexes:obj];
        // XXX What happens if this was last entry in section?
    }];
    
    // Remove from table.
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self reloadParents];
}

- (void)checkOrphans:(Entry *)entry
{
    if ([entry.class isSubclassOfClass:[Folder class]]) {
        Folder *folder = (Folder *)entry;
        // Create a copy of the entries list so we can delete while iterating
        // over it.
        NSArray *entries = [NSArray arrayWithArray:[folder.entries array]];
        NSLog(@"ORPHAN: Clearing folder %@", folder.name);
        for (Entry *subentry in entries) {
            // Remove first so that parents.count can be checked while recursing.
            [folder removeEntriesObject:subentry];
            [self checkOrphans:subentry];
        }
        if (folder.parents.count == 0) {
            NSLog(@"ORPHAN: Permanently removing folder %@", folder.name);
            [self.managedObjectContext deleteObject:folder];
        }
    } else {
        Song *song = (Song *)entry;
        if (song.parents.count == 0) {
            NSLog(@"ORPHAN: Putting song %@ into orphaned.", song.name);
            // Put this song into the orphan folder.
            NSFetchRequest *request = [self.managedObjectModel fetchRequestTemplateForName:@"OrphanFolder"];
            NSError *error;
            NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
            Folder *orphanFolder;
            if (results==nil) {
                NSLog(@"Failed to fetch orphan folder: %@", error);
                return;
            } else if (results.count == 0) {
                // Create the orphan folder.
                orphanFolder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                                       inManagedObjectContext:self.managedObjectContext];
                orphanFolder.name = kEPOrphanFolderName;
                orphanFolder.sortOrder = @(EPSortOrderManual);
                orphanFolder.addDate = [NSDate date];
                orphanFolder.releaseDate = [NSDate distantPast];
                orphanFolder.playDate = [NSDate distantPast];
                // Load root folder and insert there.
                NSFetchRequest *request = [self.managedObjectModel fetchRequestTemplateForName:@"RootFolder"];
                NSError *error;
                NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
                if (results==nil || results.count==0) {
                    NSLog(@"Failed to fetch root folder: %@", error);
                    return;
                }
                Folder *rootFolder = results[0];
                [rootFolder addEntriesObject:orphanFolder];
            } else {
                orphanFolder = results[0];
            }
            [orphanFolder addEntriesObject:song];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.showingControlCells && indexPath.section==0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.sortOrder == EPSortOrderManual) {
        if (self.showingControlCells && indexPath.section == 0) {
            // Control cells cannot be moved.
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    // Adjust index for the 2 special rows if necessary.  (Manual only has 1 section.)
    assert(fromIndexPath.section!=0);
    assert(toIndexPath.section!=0);
    fromIndexPath = [NSIndexPath indexPathForRow:fromIndexPath.row inSection:fromIndexPath.section-1];
    toIndexPath = [NSIndexPath indexPathForRow:toIndexPath.row inSection:toIndexPath.section-1];
    // Figure out the entry being moved.
    Entry *entry = self.sections[fromIndexPath.section][fromIndexPath.row];
    [self.folder removeEntriesObject:entry];
    [self.folder insertObject:entry inEntriesAtIndex:toIndexPath.row];
    // Will be committed when editing is done.
    // Remove from sections.
    NSMutableArray *section = self.sections[fromIndexPath.section];
    [section removeObjectAtIndex:fromIndexPath.row];
    [section insertObject:entry atIndex:toIndexPath.row];
    // XXX What happens if this was last entry in section?
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
    // Unfortunately looks like can't have StyleInsert with multiple selection.
//    if (self.showingControlCells && indexPath.section == 0) {
//        if (indexPath.row == 1) {
//            // Insert new folder cell.
//            return UITableViewCellEditingStyleInsert;
//        } else {
//            return UITableViewCellEditingStyleNone;
//        }
//    } else {
//        // Existing cell.
//        return UITableViewCellEditingStyleNone;
//    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView
    targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
           toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section==0) {
        return [NSIndexPath indexPathForRow:0 inSection:1];
    } else {
        return proposedDestinationIndexPath;
    }
}


/*****************************************************************************/
/* Insert Cell/Text Field                                                    */
/*****************************************************************************/


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Insert.
    if ([textField.text length]) {
        [self addFolderWithText:textField.text];
        // Reset the insert cell so you can add another.
        textField.text = nil;
    }
}

- (NSIndexPath *)cellIndexPathForField:(UITextField *)textField
{
    UITableViewCell *parentCell = (UITableViewCell *)[[textField superview] superview];
    return [self.tableView indexPathForCell:parentCell];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)addFolderWithText:(NSString *)text
{
    // New folder.
    Folder *folder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                             inManagedObjectContext:self.managedObjectContext];
    folder.name = text;
    folder.sortOrder = @(EPSortOrderManual);
    folder.addDate = [NSDate date];
    folder.releaseDate = [NSDate distantPast];
    folder.playDate = [NSDate distantPast];
    
    // Insert into the parent folder.
    [self.folder insertObject:folder inEntriesAtIndex:0];
    // Add to sections.  This will get resorted later.
    NSMutableArray *section;
    if (self.sections.count) {
        section = self.sections[0];
    } else {
        section = [NSMutableArray arrayWithCapacity:10];
        [self.sections addObject:section];
    }
    [section insertObject:folder atIndex:0];
    
    [self.tableView beginUpdates];
    // Insert the newly created folder.
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}


/*****************************************************************************/
/* Rename                                                                    */
/*****************************************************************************/
- (void)rename:(id)sender
{
    BOOL renaming = !self.renaming;
    self.renaming = renaming;
    UIButton *b = sender;
    b.selected = renaming;
//    b.highlighted = YES;
    // Enable the text fields.
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell.class isSubclassOfClass:EPBrowserCell.class]) {
            EPBrowserCell *bcell = (EPBrowserCell *)cell;
            bcell.textView.enabled = renaming;
        }
    }
}

- (void)rename:(EPBrowserCell *)cell to:(NSString *)newText
{
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    Entry *entry = self.sections[path.section-1][path.row];
    entry.name = newText;
    // Will save when editing done.
}

/*****************************************************************************/
/* Cut/Copy/Paste                                                            */
/*****************************************************************************/

- (BOOL)preventOrphanSelection:(NSString *)action emptyDeleteOK:(BOOL)emptyDeleteOK
{
    if (self.folder.parents.count == 0) {
        Folder *orphanFolder = nil;
        for (Entry *entry in self.folder.entries) {
            if ([entry.name compare:kEPOrphanFolderName] == NSOrderedSame) {
                orphanFolder = (Folder *)entry;
                break;
            }
        }
        if (orphanFolder) {
            if (orphanFolder.entries.count == 0 && emptyDeleteOK) {
                return NO;
            }
            for (NSIndexPath *path in [self.tableView indexPathsForSelectedRows]) {
                Entry *entry = self.sections[path.section-1][path.row];
                if (entry == orphanFolder) {
                    NSString *message = [NSString stringWithFormat:@"Cannot %@ the orphaned songs folder.", action];
                    UIAlertView *alert = [[UIAlertView alloc]
                                          initWithTitle:@"Operation Not Permitted"
                                          message:message
                                          delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)delete:(id)sender
{
    if ([self preventOrphanSelection:@"delete" emptyDeleteOK:YES]) {
        return;
    }
    // Display a confirmation.
    NSString *title = [NSString stringWithFormat:@"Really delete %i items?",
                       self.tableView.indexPathsForSelectedRows.count];
    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:title
                                 delegate:self
                        cancelButtonTitle:@"Cancel"
                   destructiveButtonTitle:@"Delete"
                        otherButtonTitles:nil];
    [sheet showFromTabBar:self.tabBarController.tabBar];

}
//UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self deleteRows:[self.tableView indexPathsForSelectedRows] checkOrphans:YES];
    }
}

- (void)cut:(id)sender
{
    if([self preventOrphanSelection:@"cut" emptyDeleteOK:NO]) {
        return;
    }
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
    [self doCopyWithCut:YES];
    // Remove these entries (shallow).
    [self deleteRows:indexPaths checkOrphans:NO];
}

- (Folder *)cutFolder
{
    if (_cutFolder == nil) {
        NSFetchRequest *request = [self.managedObjectModel fetchRequestTemplateForName:@"CutFolder"];
        NSError *error;
        NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (results==nil || results.count==0) {
            NSLog(@"Failed to fetch cut folder: %@", error);
            return nil;
        }
        _cutFolder = results[0];        
    }
    return _cutFolder;
}

- (void)clearCutFolder
{
    for (Entry *entry in self.cutFolder.entries) {
        NSLog(@"Clearing Cut Folder: %@", entry.name);
        [self checkOrphans:entry];
    }
    [self.cutFolder removeEntries:self.cutFolder.entries];
}

- (void)copy:(id)sender
{
    if([self preventOrphanSelection:@"copy" emptyDeleteOK:NO]) {
        return;
    }
    [self doCopyWithCut:NO];
}

- (void)doCopyWithCut:(BOOL)doCut
{
    [self clearCutFolder];
    NSMutableArray *copyItems = [NSMutableArray arrayWithCapacity:self.tableView.indexPathsForSelectedRows.count];
    for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
        // Figure out the entry being copied.
        Entry *entry = self.sections[path.section-1][path.row];
        //NSDictionary *item = @{kEPEntryUTI: [[entry objectID] URIRepresentation]};
        [copyItems addObject:[[entry objectID] URIRepresentation]];
        // Clear the current selection.
        [self.tableView deselectRowAtIndexPath:path animated:YES];
        if (doCut) {
            // Move entry to the cut folder.
            [self.cutFolder addEntriesObject:entry];
        }
    }
    playlistPasteboard.URLs = copyItems;
}

- (void)paste:(id)sender
{
    // XXX Verify any pasted folders are not self or any parents.
    for (NSURL *objURI in playlistPasteboard.URLs) {
        if (objURI) {
            NSManagedObjectID *objID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:objURI];
            if (objID) {
                Entry *entry = (Entry *)[self.managedObjectContext objectWithID:objID];
                if (entry) {
                    [self.folder addEntriesObject:entry];
                    // Remove (it may not be in there).
                    [self.cutFolder removeEntriesObject:entry];
                }
            }
        }
    }
    // Clear out the cut folder in case we aren't pasting from there.
    [self clearCutFolder];
    [self updateSections];
    [self.tableView reloadData];
    
}

@end
