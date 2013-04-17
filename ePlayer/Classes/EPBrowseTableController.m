//
//  EPBrowseTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/14/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPBrowseTableController.h"
#import "AppDelegate.h"

NSUInteger minEntriesForSections = 10;

@interface EPBrowseTableController ()

@end

@implementation EPBrowseTableController

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
    // This seems to be bugged in Interface Builder.
    self.tableView.sectionIndexMinimumDisplayRowCount = 10;
    UINib *entryNib = [UINib nibWithNibName:@"EntryCell" bundle:nil];
    [self.tableView registerNib:entryNib
         forCellReuseIdentifier:@"EntryCell"];
    
    AppDelegate *appD = (AppDelegate *)[UIApplication sharedApplication].delegate;

    UIBarButtonItem *queueButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Queue"
                                    style:UIBarButtonItemStylePlain
                                    target:appD
                                    action:@selector(queueTapped:)];
    self.navigationItem.rightBarButtonItem = queueButton;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    // Update the sort order indicator.
    UIViewController *vc = self.tabBarController.viewControllers[3];
    vc.tabBarItem.title = nameForSortOrder(self.sortOrder);
}
//
//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
/*****************************************************************************/
/* Table Data Source                                                         */
/*****************************************************************************/
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (self.sectionTitles != nil) {
        return [self.sectionTitles count];
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.sections != nil) {
        return [[self.sections objectAtIndex:section] count];
    } else {
        return 0;
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
/* Section Methods                                                           */
/*****************************************************************************/

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sectionTitles[section];
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // Currently using same section titles for index titles.
    return self.sectionTitles;
}


- (NSInteger)tableView:(UITableView *)tableView
sectionForSectionIndexTitle:(NSString *)title
               atIndex:(NSInteger)index
{
    // Section indicies are the same as index indicies.
    return index;
}

/*****************************************************************************/
/* Accessors                                                                 */
/*****************************************************************************/

- (void)setSortOrder:(EPSortOrder)sortOrder
{
    
}

- (EPSortOrder)sortOrder
{
    return EPSortOrderAlpha;
}

@end
