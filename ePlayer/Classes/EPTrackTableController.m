//
//  EPTitleTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/11/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "EPTrackTableController.h"

@interface EPTrackTableController ()

@end

@implementation EPTrackTableController

- (BOOL)wantsSearch
{
    return NO;
}

- (void)setSOButtonToSortOrder
{
    // Cheesy way to disable sort order button.
}

- (EPSortOrder)sortOrder
{
    return EPSortOrderManual;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.tracks.count;
}

- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel
{
    MPMediaItem *song = self.tracks[indexPath.row];
    cell.labelView.text = [song valueForProperty:MPMediaItemPropertyTitle];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
