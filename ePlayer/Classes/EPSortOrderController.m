//
//  EPSortOrderController.m
//  ePlayer
//
//  Created by Eric Huss on 4/15/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPSortOrderController.h"
#import "EPBrowseTableController.h"

@interface EPSortOrderController ()

@end

@implementation EPSortOrderController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.tableView.visibleCells.count) {
        // Being redisplayed.  Set the checkmark correctly.
        for (int i=0; i<EPSortOrderMax; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (i == self.currentSortOrder) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            [cell setSelected:NO animated:NO];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // This only seems to be called the first time the table is built.
    if (indexPath.row == self.currentSortOrder) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != self.currentSortOrder) {
        // Deselect the current choice.
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:self.currentSortOrder inSection:0];
//        [tableView deselectRowAtIndexPath:oldIndexPath animated:YES];
        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
        oldCell.accessoryType = UITableViewCellAccessoryNone;
        // Select the new one.
//        [tableView selectRowAtIndexPath:indexPath
//                               animated:YES
//                         scrollPosition:UITableViewScrollPositionNone];
        UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.currentSortOrder = indexPath.row;
        // Allow the selection to show.
        [self performSelector:@selector(switchOut:) withObject:nil afterDelay:0.1];
    }
}

- (void)switchOut:(id)unused
{
    // Let the previous tab know what the selection was.
    UINavigationController *navCont = self.tabBarController.viewControllers[self.previousControllerIndex];
    EPBrowseTableController *cont = (EPBrowseTableController *)navCont.topViewController;
    cont.sortOrder = self.currentSortOrder;

    // Switch to the previous tab.
    self.tabBarController.selectedIndex = self.previousControllerIndex;
}


@end
