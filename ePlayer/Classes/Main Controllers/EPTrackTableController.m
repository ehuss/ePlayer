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
    cell.textView.text = [song valueForProperty:MPMediaItemPropertyTitle];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.playerController changeQueueItems:self.tracks keepPlaying:NO];
    MPMediaItem *item = self.tracks[indexPath.row];
    self.playerController.player.nowPlayingItem = item;
    [self.playerController play];
    self.tabBarController.selectedIndex = 3;
}

/*****************************************************************************/
/* Action Methods                                                            */
/*****************************************************************************/

- (void)playTapped:(UITapGestureRecognizer *)gesture
{
    // Determine which entry was tapped.
    UITableViewCell *cell = (UITableViewCell *)[[[gesture view] superview] superview];
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForCell:cell];
    [self.playerController playItems:@[self.tracks[tappedIndexPath.row]]];
    self.tabBarController.selectedIndex = 3;
}

- (void)playAppend:(NSIndexPath *)path
{
    [self.playerController addQueueItems:@[self.tracks[path.row]]];
}


@end
