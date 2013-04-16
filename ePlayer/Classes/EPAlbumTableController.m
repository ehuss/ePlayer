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

@interface EPAlbumTableController ()

@end

@implementation EPAlbumTableController

- (void)loadAlbums
{
    if (self.albums == nil) {
        MPMediaQuery *albumQuery = [MPMediaQuery albumsQuery];
        self.albums = albumQuery.collections;
    }
    self.collation = [UILocalizedIndexedCollation currentCollation];
    // An array of sections.
    NSInteger sectionTitlesCount = self.collation.sectionTitles.count;
    self.sections = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    // Populate sections with empty arrays we will fill.
    for (int i=0; i<sectionTitlesCount; i++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [self.sections addObject:array];
    }
    // Go through the albums and add them to the appropriate sections.
    for (MPMediaItemCollection *album in self.albums) {
        EPMediaItemWrapper *wrapper = [EPMediaItemWrapper wrapperFromItem:[album representativeItem]];
        NSInteger sectionNumber = [self.collation sectionForObject:wrapper
                                           collationStringSelector:@selector(albumTitle)];
        NSMutableArray *array = [self.sections objectAtIndex:sectionNumber];
        [array addObject:wrapper];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadAlbums];
    // This seems to be bugged in Interface Builder.
    self.tableView.sectionIndexMinimumDisplayRowCount = 40;

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
    NSArray *albums = [self.sections objectAtIndex:indexPath.section];
    EPMediaItemWrapper *album = [albums objectAtIndex:indexPath.row];
    cell.textLabel.text = album.albumTitle;    
    return cell;
}

/*****************************************************************************/
/* Section Methods                                                           */
/*****************************************************************************/

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.sections[section] count]) {
        return [[self.collation sectionTitles] objectAtIndex:section];
    } else {
        // Don't show empty sections.
        return nil;
    }
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *albums = [self.sections objectAtIndex:indexPath.section];
    EPMediaItemWrapper *album = [albums objectAtIndex:indexPath.row];
    
    EPTrackTableController *trackController = [[EPTrackTableController alloc]
                                               initWithStyle:UITableViewStylePlain];
    MPMediaQuery *trackQuery = [[MPMediaQuery alloc] init];
    MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate
                                      predicateWithValue:album.albumPersistentID
                                      forProperty:MPMediaItemPropertyAlbumPersistentID];
    [trackQuery addFilterPredicate:pred];
    trackController.tracks = trackQuery.items;
    [self.navigationController pushViewController:trackController animated:YES];
}


@end
