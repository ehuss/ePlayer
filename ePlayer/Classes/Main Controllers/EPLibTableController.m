//
//  EPLibTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/19/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPLibTableController.h"

@implementation EPLibTableController

- (NSArray *)supportedSortOrders
{
    return @[@(EPSortOrderAlpha),
             @(EPSortOrderPlayDate),
             @(EPSortOrderReleaseDate)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setSOButtonToSortOrder];
    self.controlCells = @[[self createSortOrderCell]];
}

/*****************************************************************************/
/* The "Sort Order" Button                                                   */
/*****************************************************************************/

- (void)touchSortOrder:(id)sender
{
    [self setSOButtonToSortOrder];
    [super touchSortOrder:sender];
}

- (void)setSOButtonToSortOrder
{
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Sort Order"
                                     style:UIBarButtonItemStyleBordered
                                    target:self action:@selector(touchedNavSortOrder:)];
    // Enable indexes.
    self.indexesEnabled = YES;
}

- (void)setSOButtonToDone
{
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(touchedSODone:)];
    // Disable indexes.
    self.indexesEnabled = NO;
}

- (void)touchedNavSortOrder:(UIBarButtonItem *)sender
{
    // Add row at the top to set sort order.
    self.showingControlCells = YES;
    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    // Scroll to this new cell.
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop animated:YES];
    // Change button to "Done".
    [self setSOButtonToDone];
}

- (void)touchedSODone:(id)sender
{
    self.showingControlCells = NO;
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    [self setSOButtonToSortOrder];
}

@end
