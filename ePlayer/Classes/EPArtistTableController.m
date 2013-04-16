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

- (void)loadArtists
{
    MPMediaQuery *artists = [[MPMediaQuery alloc] init];
    [artists setGroupingType:MPMediaGroupingAlbumArtist];
    self.artists = artists.collections;
    self.collation = [UILocalizedIndexedCollation currentCollation];
    // An array of sections.
    NSInteger sectionTitlesCount = self.collation.sectionTitles.count;
    self.sections = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    // Populate sections with empty arrays we will fill.
    for (int i=0; i<sectionTitlesCount; i++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [self.sections addObject:array];
    }
    // Go through the artists and add them to the appropriate sections.
    for (MPMediaItemCollection *artist in self.artists) {
        EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:[artist representativeItem]];
        NSInteger sectionNumber = [self.collation sectionForObject:wrapper
                                           collationStringSelector:@selector(albumArtist)];
        NSMutableArray *array = [self.sections objectAtIndex:sectionNumber];
        [array addObject:wrapper];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadArtists];
    //self.tableView.sectionIndexMinimumDisplayRowCount = 40;

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


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.collation sectionTitles] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.sections objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntryCell"];
    // Configure the cell...
    NSArray *artists = [self.sections objectAtIndex:indexPath.section];
    EPMediaItemWrapper *artist = [artists objectAtIndex:indexPath.row];
    cell.textLabel.text = artist.albumArtist;
    
    return cell;
}

/*****************************************************************************/
/* Section Methods                                                           */
/*****************************************************************************/

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self.collation sectionTitles] objectAtIndex:section];
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.collation sectionIndexTitles];
}


- (NSInteger)tableView:(UITableView *)tableView
sectionForSectionIndexTitle:(NSString *)title
               atIndex:(NSInteger)index
{
    return [self.collation sectionForSectionIndexTitleAtIndex:index];
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
    //[tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *artists = [self.sections objectAtIndex:indexPath.section];
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
