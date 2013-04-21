//
//  EPMediaTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "EPArtistTableController.h"
#import "EPAlbumTableController.h"
#import "EPMediaItemWrapper.h"

@interface EPArtistTableController ()

@end

@implementation EPArtistTableController

- (NSString *)filterPropertyName
{
    return @"albumArtist";
}

- (void)loadArtists
{
    MPMediaQuery *artists = [[MPMediaQuery alloc] init];
    [artists setGroupingType:MPMediaGroupingAlbumArtist];
    self.artists = artists.collections;
    [self updateSections];
}

- (void)updateSections
{
    // Sort the artists.
    NSArray *wrappedArtists = [self.artists mapWithBlock:^id(id item) {
        return [EPMediaItemWrapper wrapperFromItem:[(MPMediaItemCollection *)item representativeItem]];
    }];
    NSArray *sortedArtists = [EPMediaItemWrapper sortedArrayOfWrappers:wrappedArtists
                                                              inOrder:self.sortOrder
                                                             alphaKey:@"albumArtist"];
    
    // Divy the ablums into sections.
    if (sortedArtists.count > minEntriesForSections) {
        NSMutableArray *sections = [[NSMutableArray alloc] init];
        self.sections = sections;
        self.sectionTitles = [[NSMutableArray alloc] init];
        NSMutableArray *currentSection = nil;
        NSString *currentSectionTitle = nil;
        for (EPMediaItemWrapper *wrapper in sortedArtists) {
            NSString *sectionTitle = [wrapper sectionTitleForSortOrder:self.sortOrder
                                                              alphaKey:MPMediaItemPropertyAlbumArtist];
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
        self.sections = [NSMutableArray arrayWithObject:wrappedArtists];
        self.sectionTitles = [NSMutableArray arrayWithObject:@""];
    }
    
}

- (void)setSortOrder:(EPSortOrder)sortOrder
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:sortOrder forKey:EPSettingArtistsSortOrder];
    [self updateSections];
    [self.tableView reloadData];
}


- (EPSortOrder)sortOrder
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults valueForKey:EPSettingArtistsSortOrder] intValue];
}


- (void)viewDidLoad
{
    [self loadArtists];
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

- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel
{
    NSArray *artists = [sections objectAtIndex:indexPath.section];
    EPMediaItemWrapper *artist = [artists objectAtIndex:indexPath.row];
    cell.labelView.text = artist.albumArtist;

    if (useDateLabel) {
        cell.dateLabel.text = [artist sectionTitleForSortOrder:self.sortOrder
                                                      alphaKey:MPMediaItemPropertyAlbumArtist];
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
/* Table Delegate Methods                                                    */
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
    NSArray *artists = [data objectAtIndex:indexPath.section];
    EPMediaItemWrapper *artist = [artists objectAtIndex:indexPath.row];
    
    EPAlbumTableController *albumController = [[EPAlbumTableController alloc]
                                                     initWithStyle:UITableViewStylePlain];
    MPMediaQuery *albumsQuery = [[MPMediaQuery alloc] init];
    [albumsQuery setGroupingType:MPMediaGroupingAlbum];
    MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate
                                      predicateWithValue:artist.albumArtist
                                      forProperty:MPMediaItemPropertyAlbumArtist];
    [albumsQuery addFilterPredicate:pred];
    albumController.albums = albumsQuery.collections;
    [self.navigationController pushViewController:albumController animated:YES];
}

@end
