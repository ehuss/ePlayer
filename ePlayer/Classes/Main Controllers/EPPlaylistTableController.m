//
//  EPEntryTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "EPPlaylistTableController.h"
#import "EPCommon.h"
#import "EPPlayerController.h"
#import "EPTrackController.h"

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
    // Be careful not to access the view here, some things in viewDidLoad need
    // self.sections to be set up.
    return controller;
}

- (void)setSortOrder:(EPSortOrder)sortOrder
{
    self.folder.sortOrder = sortOrder;
    self.root.dirty = YES;
    [self updateSections];
    [self.tableView reloadData];
}

- (EPSortOrder)sortOrder
{
    return self.folder.sortOrder;
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
        NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"EditCell"
                                                          owner:self
                                                        options:nil];
        self.editCell1 = nibViews[0];
        self.editCell2 = nibViews[1];
        [self.editCell1.deleteButton addTarget:self action:@selector(delete:)
               forControlEvents:UIControlEventTouchUpInside];
        [self.editCell1.cutButton addTarget:self action:@selector(cut:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.editCell1.cpyButton addTarget:self action:@selector(copy:)
             forControlEvents:UIControlEventTouchUpInside];
        [self.editCell1.pasteButton addTarget:self action:@selector(paste:)
              forControlEvents:UIControlEventTouchUpInside];

        [self.editCell2.renameButton addTarget:self action:@selector(rename:)
               forControlEvents:UIControlEventTouchUpInside];
        [self.editCell2.addFolderButton addTarget:self action:@selector(addFolder:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.editCell2.collapseButton addTarget:self action:@selector(collapse:)
           forControlEvents:UIControlEventTouchUpInside];
        
        _controlCells = @[[self createSortOrderCell],
                          self.editCell1,
                          self.editCell2];
    }
    return _controlCells;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.editing) {
        // Hit the back button while editing.  It won't turn editing off, so
        // do anything that needs to be done.
        [self reloadParents];
    }
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
#pragma mark - Table view data source
/*****************************************************************************/

// Populates the labels for a cell with the values for an entry.
- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel
{
    EPEntry *entry = sections[indexPath.section][indexPath.row];
    cell.entry = entry;
    cell.textView.text = entry.name;
    if (entry.duration > 120*60) {
        cell.timeLabel.text = [NSString stringWithFormat:@"%ih", (int)entry.duration/(60*60)];
    } else {
        cell.timeLabel.text = [NSString stringWithFormat:@"%i:%02i",
                               (int)entry.duration/60, (int)entry.duration%60
                               ];
    }
    if (self.indexesEnabled) {
        cell.timeLabel.center = CGPointMake(258, cell.timeLabel.center.y);
    } else {
        cell.timeLabel.center = CGPointMake(279, cell.timeLabel.center.y);
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (useDateLabel) {
        cell.dateLabel.text = [self.folder sectionTitleForEntry:entry];
    }    
}


/*****************************************************************************/
#pragma mark - Action Methods
/*****************************************************************************/

- (void)playTapped:(UITapGestureRecognizer *)gesture
{
    // Determine which entry was tapped.
    EPBrowserCell *cell = (EPBrowserCell *)[[[gesture view] superview] superview];
    [self.playerController playEntry:cell.entry];
    self.tabBarController.selectedIndex = 3;
}

- (void)playAppend:(NSIndexPath *)path
{
    EPEntry *entry = self.sections[path.section][path.row];
    [self.playerController appendEntry:entry];
}


/*****************************************************************************/
#pragma mark - Table view delegate
/*****************************************************************************/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        [self updateEditCellStatus];
        return;
    }
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSections;
    } else {
        data = self.sections;
    }
    EPEntry *entry = data[indexPath.section][indexPath.row];
    if ([entry isKindOfClass:[EPFolder class]]) {
        EPPlaylistTableController *controller = [self copyMusicController];
        controller.folder = (EPFolder *)entry;
        [self.navigationController pushViewController:controller animated:YES];
    } else {
        // A song.
        EPTrackController *controller = [self.tabBarController.storyboard instantiateViewControllerWithIdentifier:@"TrackController"];
        [controller loadSong:(EPSong *)entry];
        controller.trackSummary.infoButton.hidden = YES;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        [self updateEditCellStatus];
    }
}

- (void)setFolder:(EPFolder *)folder
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
        for (EPEntry *entry in sortedEntries) {
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
        self.indexesEnabled = YES;
    } else {
        self.sections = [NSMutableArray arrayWithObject:
                         [NSMutableArray arrayWithArray:sortedEntries]];
        self.sectionTitles = [NSMutableArray arrayWithObject:@""];
        self.indexesEnabled = NO;
    }
}

/*****************************************************************************/
#pragma mark - Editting Support
/*****************************************************************************/
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    if (editing) {
        self.showingControlCells = YES;
        self.indexesEnabled = NO;
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        // Make sure enabled status on buttons is correct.
        [self updateEditCellStatus];        
    } else {
        // Commit editing changes.
        if (self.showingControlCells) {
            // Save any changes made.
            self.root.dirty = YES;
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
            // Update previous tables.
            [self reloadParents];
        }
    }
}

- (void)updateEditCellStatus
{
    BOOL haveSelections = self.tableView.indexPathsForSelectedRows.count != 0;
    self.editCell1.deleteButton.enabled = haveSelections;
    self.editCell1.cutButton.enabled = haveSelections;
    self.editCell1.cpyButton.enabled = haveSelections;
    self.editCell2.collapseButton.enabled = haveSelections;
    BOOL havePasteItems = playlistPasteboard.URLs.count != 0;
    self.editCell1.pasteButton.enabled = havePasteItems;
}

- (void)reloadParents
{
    // Tell any table controllers higher in the chain to reload, just in case
    // anything changed (dates, etc.).
    for (EPPlaylistTableController *controller in self.navigationController.viewControllers) {
        if (controller != self) {
            [controller updateSections];
            [controller.tableView reloadData];
        }
    }
}

- (void)deleteRows:(NSArray *)indexPaths checkOrphans:(BOOL)doCheckOrphans
{
    // Determine the entries to delete.
    NSMutableArray *entriesToDelete = [NSMutableArray arrayWithCapacity:indexPaths.count];
    // Remove from sections.  I'm not sure if indexPaths is guaranteed to be
    // grouped by sections.  We need a set of indicies per section.
    // Key is NSNumber section number, value is NSIndexSet.
    NSMutableDictionary *sectionsToDelete = [NSMutableDictionary dictionaryWithCapacity:indexPaths.count];
    for (NSIndexPath *path in indexPaths) {
        // Adjust index for the 2 special rows if necessary.
        NSIndexPath *realIndexPath = [NSIndexPath indexPathForRow:path.row inSection:path.section-1];
        // Figure out the entry being removed.
        EPEntry *entry = self.sections[realIndexPath.section][realIndexPath.row];
        NSLog(@"Deleting %@", entry.name);
        [entriesToDelete addObject:entry];
        // Add to the set of section data to clean up.
        NSNumber *sectionNumber = [NSNumber numberWithInteger:realIndexPath.section];
        NSMutableIndexSet *indexSet = [sectionsToDelete objectForKey:sectionNumber];
        if (indexSet == nil) {
            indexSet = [[NSMutableIndexSet alloc] init];
            [sectionsToDelete setObject:indexSet forKey:sectionNumber];
        }
        [indexSet addIndex:realIndexPath.row];
    }
    [self.folder removeEntries:entriesToDelete];
    // Will be committed when editing is done.

    if (doCheckOrphans) {
        for (EPEntry *entry in entriesToDelete) {
            // If any songs in this entry have no parents, put it into a special
            // orphan folder.  Otherwise there would be no way to ever access them.
            [entry checkForOrphan];
        }
    }

    [sectionsToDelete enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSMutableIndexSet *obj, BOOL *stop) {
        NSMutableArray *section = self.sections[key.integerValue];
        [section removeObjectsAtIndexes:obj];
        // XXX What happens if this was last entry in section?
    }];
    
    // Remove from table.
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self reloadParents];
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
    EPEntry *entry = self.sections[fromIndexPath.section][fromIndexPath.row];
    [self.folder removeObjectFromEntriesAtIndex:fromIndexPath.row];
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
#pragma mark - Insert Cell/Text Field
/*****************************************************************************/


- (void)addFolderWithText:(NSString *)text
{
    // New folder.
    EPFolder *folder = [EPFolder folderWithName:text
                                      sortOrder:EPSortOrderManual
                                    releaseDate:[NSDate distantPast]
                                        addDate:[NSDate date]
                                       playDate:[NSDate distantPast]];
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

- (void)addFolder:(id)sender
{
    self.focusAddFolder = YES;
    _renaming = YES;
    [self addFolderWithText:@""];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (self.focusAddFolder && cell && indexPath.section==1 && indexPath.row==0) {
        EPBrowserCell *bcell = (EPBrowserCell *)cell;
        bcell.textView.enabled = YES;
        // Unfortunately, becomreFirstResponder won't work until the view is actually up.
        // UITableView does not provide a callback *after* a cell has been added/displayed.
        [bcell.textView performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.2];
    }
    return cell;
}



/*****************************************************************************/
#pragma mark - Rename
/*****************************************************************************/
- (void)rename:(id)sender
{
    self.renaming = !self.renaming;
}

- (void)setRenaming:(BOOL)renaming
{
    _renaming = renaming;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    if (cell) {
        UIButton *renameButton = (UIButton *)[cell viewWithTag:1];
        renameButton.selected = renaming;
    }
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
    EPEntry *entry = self.sections[path.section-1][path.row];
    entry.name = newText;
    // Will save when editing done.
    if (self.focusAddFolder) {
        // Unfocus.
        self.focusAddFolder = NO;
        self.renaming = NO;        
    }
}

/*****************************************************************************/
#pragma mark - Cut/Copy/Paste
/*****************************************************************************/

- (BOOL)preventOrphanSelection:(NSString *)action emptyDeleteOK:(BOOL)emptyDeleteOK
{
    if (self.folder.parents.count == 0) {
        EPFolder *orphanFolder = nil;
        for (EPEntry *entry in self.folder.entries) {
            if ([entry.name compare:kEPOrphanFolderName] == NSOrderedSame) {
                orphanFolder = (EPFolder *)entry;
                break;
            }
        }
        if (orphanFolder) {
            if (orphanFolder.entries.count == 0 && emptyDeleteOK) {
                return NO;
            }
            for (NSIndexPath *path in [self.tableView indexPathsForSelectedRows]) {
                EPEntry *entry = self.sections[path.section-1][path.row];
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
        NSString *name = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([name compare:@"Delete"] == NSOrderedSame) {
            [self deleteRows:[self.tableView indexPathsForSelectedRows] checkOrphans:YES];
        } else if ([name compare:@"Collapse"] == NSOrderedSame) {
            [self collapseRows:[self.tableView indexPathsForSelectedRows]];
        }
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

- (EPRoot *)root
{
    if (_root == nil) {
        _root = [EPRoot sharedRoot];
    }
    return _root;
}

- (void)clearCutFolder
{
    // Make a copy so we can iterate over them after removing them from the folder.
    NSArray *entries = [NSArray arrayWithArray:self.root.cut.entries];
    [self.root.cut removeAllEntries];
    for (EPEntry *entry in entries) {
        NSLog(@"Checking cut song: %@", entry.name);
        [entry checkForOrphan];
    }
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
        EPEntry *entry = self.sections[path.section-1][path.row];
        [copyItems addObject:entry.url];
        // Clear the current selection.
        [self.tableView deselectRowAtIndexPath:path animated:YES];
        if (doCut) {
            // Move entry to the cut folder.
            [self.root.cut addEntriesObject:entry];
        }
    }
    playlistPasteboard.URLs = copyItems;
    [self updateEditCellStatus];
}

- (void)paste:(id)sender
{
    NSUInteger count = 0;
    for (NSURL *objURI in playlistPasteboard.URLs) {
        if (objURI && [objURI.scheme isEqualToString:@"ePlayer"]) {
            NSLog(@"Paste URL %@", objURI);
            NSArray *components = objURI.pathComponents;
            if (components.count == 3) {
                EPEntry *entry = nil;
                NSString *type = components[1];
                if ([type isEqualToString:@"Folder"]) {
                    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:components[2]];
                    entry = [self.root folderWithUUID:uuid];
                } else if ([type isEqualToString:@"Song"]) {
                    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                    formatter.numberStyle = NSNumberFormatterDecimalStyle;
                    NSNumber *pid = [formatter numberFromString:components[2]];
                    entry = [self.root songWithPersistentID:pid];
                }
                if (entry) {
                    entry = [self checkPasteCycle:entry];
                    [self.folder addEntriesObject:entry];
                    [self.root.cut removeEntriesObject:entry];
                    count += 1;
                } else {
                    NSLog(@"Could not find %@", objURI);
                }
            } else {
                NSLog(@"Invalid paste URL: %@", objURI);
            }
        } else {
            NSLog(@"Not a valid paste URL: %@", objURI);
        }
    }
    // Clear out the cut folder in case we aren't pasting from there.
    [self clearCutFolder];
    [self updateSections];
    [self.tableView reloadData];
    // Display a little popup that indicates how many entries pasted.
    UILabel *pasteNote = [[UILabel alloc] init];
    pasteNote.text = [NSString stringWithFormat:@"Pasted %u items.", count];
    pasteNote.textColor = [UIColor whiteColor];
    pasteNote.backgroundColor = [UIColor blackColor];
    pasteNote.layer.cornerRadius = 4;
    [pasteNote sizeToFit];
    pasteNote.center = self.view.center;
    [self.view addSubview:pasteNote];
    [UIView animateWithDuration:2.0 delay:1.0 options:0 animations:^{
        pasteNote.alpha = 0;
    } completion:^(BOOL finished) {
        [pasteNote removeFromSuperview];
    }];
}

- (EPEntry *)checkPasteCycle:(EPEntry *)entry
{
    // This may not be perfect, but seems to work well enough.
    if ([entry.class isSubclassOfClass:[EPFolder class]]) {
        EPFolder *folder = (EPFolder *)entry;
        // Verify that this is not self or any parents of self.
        folder = [self fixCycles:folder];
        return folder;
    } else {
        // XXX: Make a copy if it already exists in the current folder?
        return entry;
    }
}

- (EPFolder *)fixCycles:(EPFolder *)folder
{
    if ([self folder:folder inParents:self.folder]) {
        NSLog(@"Cycle: Clone %@", folder.name);
        folder = [folder copy];
    }
    // Verify no sub-folders in folder are a parent.
    NSUInteger index = 0;
    for (EPEntry *entry in folder.entries) {
        if ([entry.class isSubclassOfClass:[EPFolder class]]) {
            EPFolder *newEntry = [self fixCycles:(EPFolder *)entry];
            if (newEntry != entry) {
                [folder replaceObjectInEntriesAtIndex:index withObject:newEntry];
            }
        }
        index += 1;
    }
    return folder;
}

- (BOOL)folder:(EPFolder *)folder inParents:(EPFolder *)inFolder
{
    if (folder == inFolder) {
        return YES;
    }
    if ([inFolder.parents containsObject:folder]) {
        return YES;
    }
    for (EPFolder *parent in inFolder.parents) {
        if ([self folder:folder inParents:parent]) {
            return YES;
        }
    }
    return NO;
}

/*****************************************************************************/
#pragma mark - Collapse
/*****************************************************************************/

- (void)collapse:(id)sender
{
    if ([self preventOrphanSelection:@"delete" emptyDeleteOK:NO]) {
        return;
    }
    // Verify that all selections are folders.
    for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
        EPEntry *entry = self.sections[path.section-1][path.row];
        if (![entry.class isSubclassOfClass:[EPFolder class]]) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Operation Not Permitted"
                                  message:@"You may only collapse folders."
                                  delegate:nil
                                  cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    // Display a confirmation.
    NSString *title = [NSString stringWithFormat:@"Really collapse %i folders?",
                       self.tableView.indexPathsForSelectedRows.count];
    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:title
                            delegate:self
                            cancelButtonTitle:@"Cancel"
                            destructiveButtonTitle:@"Collapse"
                            otherButtonTitles:nil];
    [sheet showFromTabBar:self.tabBarController.tabBar];
    
}

- (void)collapseRows:(NSArray *)indexPaths
{
    for (NSIndexPath *path in indexPaths) {
        EPFolder *folder = self.sections[path.section-1][path.row];
        [self.folder addEntries:folder.entries];
        [self.folder removeEntriesObject:folder];
        if (folder.parents.count == 0) {
            NSLog(@"Collapse: Permanently removing folder %@", folder.name);
        }
    }
    // Could call insertRowsAtIndexPaths for better animation.
    [self updateSections];
    [self.tableView reloadData];
}

@end
