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


//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    self.folder = nil;
//}
//
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


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *CellIdentifier = @"PlaylistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntryCell"];
    assert (cell != nil);
//    if (cell==nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//        
//        cell.imageView.image = [UIImage imageNamed:@"play"];
//        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
//                                              initWithTarget:self
//                                              action:@selector(playTapped:)];
//        [cell.imageView addGestureRecognizer:tapGesture];
//        cell.imageView.userInteractionEnabled = YES;
//    }
    if (!cell.imageView.gestureRecognizers.count) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(playTapped:)];
        [cell.imageView addGestureRecognizer:tapGesture];
        cell.imageView.userInteractionEnabled = YES;
    }
    Entry *entry = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = entry.name;
    if ([entry.class isSubclassOfClass:[Folder class]]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

/*****************************************************************************/
/* Action Methods                                                            */
/*****************************************************************************/

- (void)playTapped:(UITapGestureRecognizer *)gesture
{
    // Determine which entry was tapped.
    UITableViewCell *cell = (UITableViewCell *)[[[gesture view] superview] superview];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForCell:cell];
    Entry *entry = self.folder.sortedEntries[tappedIndexPath.row];
    // Stop whatever is playing.
    EPPlayerController *playerController = [EPPlayerController sharedPlayer];
    //[playerController clearQueue];
    // Add all of these items to the queue.
    NSMutableArray *newItems = [NSMutableArray arrayWithCapacity:100];
    [self addEntry:entry toArray:newItems];
    // Add these items to the queue, start playback, and display the player.
    // Guard against playing an empty folder (which would cause an exception
    // when creating the MPMediaItemCollection).
    if (newItems.count) {
        [playerController addQueueItems:newItems];
        [playerController play];
    }
    [self.navigationController pushViewController:playerController animated:YES];
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*****************************************************************************/
/* Table Delegate                                                            */
/*****************************************************************************/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Entry *entry = self.sections[indexPath.section][indexPath.row];
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
    if (self.folder.sortedEntries.count > minEntriesForSections) {
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        self.sections = sections;
        self.sectionTitles = [[NSMutableArray alloc] init];
        NSMutableArray *currentSection = nil;
        NSString *currentSectionTitle = nil;
        for (Entry *entry in self.folder.sortedEntries) {
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
        // With a small number of entries, sections are a pain.
        self.sections = @[self.folder.sortedEntries];
        self.sectionTitles = nil;
    }    
}

@end
