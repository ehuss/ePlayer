//
//  EPArtistAlbumTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "EPAlbumTableController.h"
#import "EPTrackTableController.h"
#import "EPMediaItemWrapper.h"
#import "EPCommon.h"

@interface EPAlbumTableController ()

@end

@implementation EPAlbumTableController

- (NSString *)filterPropertyName
{
    return @"albumTitle";
}

- (void)loadAlbums
{
    if (self.albums == nil) {
        MPMediaQuery *albumQuery = [MPMediaQuery albumsQuery];
        self.albums = albumQuery.collections;
        self.isGlobalAlbums = YES;
    } else {
        self.isGlobalAlbums = NO;
    }
    [self updateSections];
}

- (void)updateSections
{
    // Sort the albums.
    NSArray *wrappedAlbums = [self.albums mapWithBlock:^id(id item) {
        return [EPMediaItemWrapper wrapperFromItem:[(MPMediaItemCollection *)item representativeItem]];
    }];
    NSArray *sortedAlbums = [EPMediaItemWrapper sortedArrayOfWrappers:wrappedAlbums
                                                              inOrder:self.sortOrder
                                                             alphaKey:@"albumTitle"];

    // Divy the ablums into sections.
    if (sortedAlbums.count > minEntriesForSections) {
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        self.sections = sections;
        self.sectionTitles = [[NSMutableArray alloc] init];
        NSMutableArray *currentSection = nil;
        NSString *currentSectionTitle = nil;
        for (EPMediaItemWrapper *wrapper in sortedAlbums) {
            NSString *sectionTitle = [wrapper sectionTitleForSortOrder:self.sortOrder
                                                              alphaKey:MPMediaItemPropertyAlbumTitle];
            // Is this entry a new section?
            if (currentSection == nil || [sectionTitle compare:currentSectionTitle]!=NSOrderedSame) {
                currentSectionTitle = sectionTitle;
                [self.sectionTitles addObject:sectionTitle];
                currentSection = [[NSMutableArray alloc] init];
                [sections addObject:currentSection];
            }
            [currentSection addObject:wrapper];
        }
    } else {
        // With a small number of entries, sections are a pain.
        self.sections = [NSMutableArray arrayWithObject:wrappedAlbums];
        self.sectionTitles = [NSMutableArray arrayWithObject:@""];
    }
    
}

- (void)setSortOrder:(EPSortOrder)sortOrder
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.isGlobalAlbums) {
        [defaults setInteger:sortOrder forKey:EPSettingAllAbumsSortOrder];
    } else {
        [defaults setInteger:sortOrder forKey:EPSettingArtistAlbumsSortOrder];
    }
    [self updateSections];
    [self.tableView reloadData];
}


- (EPSortOrder)sortOrder
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.isGlobalAlbums) {
        return [[defaults valueForKey:EPSettingAllAbumsSortOrder] intValue];
    } else {
        return [[defaults valueForKey:EPSettingArtistAlbumsSortOrder] intValue];
    }
}


- (void)viewDidLoad
{
    [self loadAlbums];
    [super viewDidLoad];
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

- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel
{
    NSArray *albums = sections[indexPath.section];
    EPMediaItemWrapper *album = [albums objectAtIndex:indexPath.row];
    cell.textView.text = album.albumTitle;
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSections;
    } else {
        data = self.sections;
    }
    NSArray *albums = [data objectAtIndex:indexPath.section];
    EPMediaItemWrapper *album = [albums objectAtIndex:indexPath.row];
    
    EPTrackTableController *trackController = [[EPTrackTableController alloc]
                                               initWithStyle:UITableViewStylePlain];
    trackController.tracks = [self albumTracks:album.albumPersistentID];
    trackController.title = album.albumTitle;
    [self.navigationController pushViewController:trackController animated:YES];
}

/*****************************************************************************/
/* Action Methods                                                            */
/*****************************************************************************/

// Returns array of MPMediaItems
- (NSArray *)albumTracks:(NSNumber *)albumID
{
    MPMediaQuery *trackQuery = [[MPMediaQuery alloc] init];
    MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate
                                      predicateWithValue:albumID
                                      forProperty:MPMediaItemPropertyAlbumPersistentID];
    [trackQuery addFilterPredicate:pred];
    return trackQuery.items;
}

- (void)playTapped:(UITapGestureRecognizer *)gesture
{
    // Determine which entry was tapped.
    UITableViewCell *cell = (UITableViewCell *)[[[gesture view] superview] superview];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForCell:cell];
    EPMediaItemWrapper *album = self.sections[tappedIndexPath.section][tappedIndexPath.row];
    // XXX Is this always sorted?
    [self.playerController playItems:[self albumTracks:album.albumPersistentID]];
    self.tabBarController.selectedIndex = 3;
}

- (void)playAppend:(NSIndexPath *)path
{
    EPMediaItemWrapper *album = self.sections[path.section][path.row];
    [self.playerController addQueueItems:[self albumTracks:album.albumPersistentID]];
}



@end
