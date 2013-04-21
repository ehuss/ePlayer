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

@interface EPPlaylistTableController ()

@end

@implementation EPPlaylistTableController


- (EPPlaylistTableController *)copyMusicController
{
    EPPlaylistTableController *controller = [[EPPlaylistTableController alloc] initWithStyle:UITableViewStylePlain];
    controller.managedObjectContext = self.managedObjectContext;
    controller.managedObjectModel = self.managedObjectModel;
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


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;


    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    cell.labelView.text = entry.name;
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
    Entry *entry = self.sortedEntries[tappedIndexPath.row];
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
    self.sortedEntries = [self.folder sortedEntries];
    // With a small number of entries, sections are a pain.
    if (self.sortOrder!=EPSortOrderManual &&
            self.sortedEntries.count > minEntriesForSections) {
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        self.sections = sections;
        self.sectionTitles = [[NSMutableArray alloc] init];
        NSMutableArray *currentSection = nil;
        NSString *currentSectionTitle = nil;
        for (Entry *entry in self.sortedEntries) {
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
                         [NSMutableArray arrayWithArray:self.sortedEntries]];
        self.sectionTitles = [NSMutableArray arrayWithObject:@""];
    }
}

/*****************************************************************************/
/* Editting Support                                                          */
/*****************************************************************************/
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    // Add rows at the top to add a new folder and set sort order.
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                            [NSIndexPath indexPathForRow:1 inSection:0]
                            ];

    if (editing) {
        self.hasInsertCell = YES;
        self.hasSortCell = YES;
        self.indexesEnabled = NO;
        [self.tableView insertRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        if (self.hasInsertCell) {
            // Save any changes made.
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Failed to save: %@", error);
            }
            // Clean up.
            self.hasInsertCell = NO;
            self.hasSortCell = NO;
            self.indexesEnabled = YES;
            [self.tableView deleteRowsAtIndexPaths:indexPaths
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
            [self deleteRow:indexPath];            
            break;
        }
            
        case UITableViewCellEditingStyleInsert: {
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

- (void)deleteRow:(NSIndexPath *)indexPath
{
    // Adjust index for the 2 special rows if necessary.
    NSIndexPath *realIndexPath = indexPath;
    if (indexPath.section==0) {
        realIndexPath = [NSIndexPath indexPathForRow:indexPath.row-2 inSection:indexPath.section];
    }
    // Figure out the entry being removed.
    Entry *entry = self.sections[realIndexPath.section][realIndexPath.row];
    [self.folder removeEntriesObject:entry];
    // Will be committed when editing is done.
    // Remove from sections.
    NSMutableArray *section = self.sections[realIndexPath.section];
    [section removeObjectAtIndex:realIndexPath.row];
    // XXX What happens if this was last entry in section?
    // Remove from table.
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    // If any songs in this entry have no parents, put it into a special
    // orphan folder.  Otherwise there would be no way to ever access them.
    [self checkOrphans:entry];
}

- (void)checkOrphans:(Entry *)entry
{
    if ([entry.class isSubclassOfClass:[Folder class]]) {
        Folder *folder = (Folder *)entry;
        NSArray *entries = [folder.entries array];
        for (Entry *subentry in entries) {
            [folder removeEntriesObject:subentry];
            [self checkOrphans:subentry];
        }
        if (folder.parents.count == 0) {
            [self.managedObjectContext deleteObject:folder];
        }
    } else {
        Song *song = (Song *)entry;
        if (song.parents.count == 0) {
            NSLog(@"Putting song into orphaned.");
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
                orphanFolder.name = @"Orphaned Songs";
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
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.sortOrder == EPSortOrderManual) {
        if (self.hasSortCell && indexPath.row==0 && indexPath.section==0) {
            return NO;
        } else if (self.hasInsertCell && indexPath.row==1 && indexPath.section==0) {
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
    assert(fromIndexPath.section==0);
    assert(toIndexPath.section==0);
    fromIndexPath = [NSIndexPath indexPathForRow:fromIndexPath.row-2 inSection:fromIndexPath.section];
    toIndexPath = [NSIndexPath indexPathForRow:toIndexPath.row-2 inSection:toIndexPath.section];
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
    if (self.hasSortCell && indexPath.section==0 && indexPath.row==0) {
        // Sort order cell.
        return UITableViewCellEditingStyleNone;
    } else if (self.hasInsertCell && indexPath.section==0 && indexPath.row==1) {
        // Insert new folder cell.
        return UITableViewCellEditingStyleInsert;
    } else {
        // Existing cell.
        return UITableViewCellEditingStyleDelete;
    }
}
- (NSIndexPath *)tableView:(UITableView *)tableView
    targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
           toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section==0 && (proposedDestinationIndexPath.row==0 ||
                                                    proposedDestinationIndexPath.row==1)) {
        return [NSIndexPath indexPathForRow:2 inSection:0];
    } else {
        return proposedDestinationIndexPath;
    }
}


/*****************************************************************************/
/* Insert Cell                                                               */
/*****************************************************************************/

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //NSIndexPath *currRow = [self cellIndexPathForField:textField];
    if ([textField.text length]) {
        [self addFolderWithText:textField.text];
    }
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
    }
    [section insertObject:folder atIndex:0];
    
    [self.tableView beginUpdates];
    // Reload the "insert" cell.
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    // Insert the newly created folder.
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}


@end
