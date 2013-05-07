//
//  EPGearTableController.m
//  ePlayer
//
//  Created by Eric Huss on 5/6/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPGearTableController.h"
#import "AppDelegate.h"
#import "EPMainTabController.h"
#import "EPUpdateResultsController.h"

@implementation EPGearTableController

/*****************************************************************************/
#pragma mark - Table view delegate
/*****************************************************************************/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self updateDatabaseQuery];
    }
}

/*****************************************************************************/
#pragma mark - Actions
/*****************************************************************************/

- (void)updateDatabaseQuery
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Update Database"
                          message:@"Update database now?"
                          delegate:self
                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES];
    } else if (buttonIndex == 1) {
        [self updateDatabase];
    }
}

- (void)updateDatabase
{
    AppDelegate *appD = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appD beginDBUpdate:self];
}

- (void)dbUpdateDone:(NSString *)results
{
//    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES];
    EPMainTabController *tabC = (EPMainTabController *)self.tabBarController;
    [tabC reloadBrowsers];
    EPUpdateResultsController *update = [[EPUpdateResultsController alloc] init];
    update.results = results;
    [self.navigationController pushViewController:update animated:YES];
}

@end
