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
#import "EPSettings.h"

@implementation EPGearTableController

- (void)iPodSwitchChanged:(id)sender
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if (self.iPodSwitch.on) {
        [settings setObject:kEPAudioBackendMPMusic forKey:kEPSettingAudioBackend];
    } else {
        [settings setObject:kEPAudioBackendAVAudio forKey:kEPSettingAudioBackend];
    }
    EPMainTabController *tabC = (EPMainTabController *)self.tabBarController;
    [tabC.playerController changeAudioBackend];
}

/*****************************************************************************/
#pragma mark - View Controller
/*****************************************************************************/
- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *backend = [settings stringForKey:kEPSettingAudioBackend];
    if (backend && [backend compare:kEPAudioBackendMPMusic]==NSOrderedSame) {
        self.iPodSwitch.on = YES;
    } else {
        self.iPodSwitch.on = NO;
    }
}

/*****************************************************************************/
#pragma mark - Table view delegate
/*****************************************************************************/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [self updateDatabaseQuery];
            break;
        case 1:
            [self resetDatabaseQuery];
            break;
    }
}

/*****************************************************************************/
#pragma mark - Update Database
/*****************************************************************************/

- (void)updateDatabaseQuery
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Update Database"
                          message:@"Update database now?"
                          delegate:self
                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    [alert show];
}


- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    } else if (buttonIndex == 1) {
        if ([actionSheet.title isEqualToString:@"Update Database"]) {
            [self updateDatabase];
        } else if ([actionSheet.title isEqualToString:@"Reset Database"]) {
            [self resetDatabase];
        }
    }
}

- (void)updateDatabase
{
    AppDelegate *appD = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appD beginDBUpdate:self];
}

- (void)dbUpdateDone:(NSString *)results
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    EPMainTabController *tabC = (EPMainTabController *)self.tabBarController;
    [tabC resetBrowsers];

    EPUpdateResultsController *update = [tabC.storyboard instantiateViewControllerWithIdentifier:@"UpdateResults"];
    // Force the views to load.
    [update view];
    update.textView.text = results;
    // I'm not certain why, but when you change the text of the text view,
    // it's scroll position is somewhere in the middle.  This forces it to
    // scroll to the top.
    [update.textView scrollRangeToVisible:NSMakeRange(0, 0)];
    [self presentViewController:update animated:YES completion:nil];
}

/*****************************************************************************/
#pragma mark - Reset Database
/*****************************************************************************/

- (void)resetDatabaseQuery
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Reset Database"
                          message:@"Are you sure you want to RESET?  All changes will be lost!"
                          delegate:self
                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"RESET", nil];
    [alert show];

}

- (void)resetDatabase
{
    AppDelegate *appD = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [appD resetDB];
    [appD performSelectorInBackground:@selector(initDB:) withObject:self];
}

- (void)dbInitDone
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    EPMainTabController *tabC = (EPMainTabController *)self.tabBarController;
    [tabC resetBrowsers];
}

@end
