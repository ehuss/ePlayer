//
//  EPBrowseTableController.m
//  ePlayer
//
//  Created by Eric Huss on 4/14/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPBrowseTableController.h"
#import "EPTableSectionView.h"
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

- (BOOL)wantsSearch
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // This seems to be bugged in Interface Builder.
    self.tableView.sectionIndexMinimumDisplayRowCount = 10;
    // Register the class for creating cells.
    UINib *entryNib = [UINib nibWithNibName:@"EntryCell" bundle:nil];
    [self.tableView registerNib:entryNib
         forCellReuseIdentifier:@"EntryCell"];
    
    // Create a queue button.
    AppDelegate *appD = (AppDelegate *)[UIApplication sharedApplication].delegate;

    UIBarButtonItem *queueButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Queue"
                                    style:UIBarButtonItemStylePlain
                                    target:appD
                                    action:@selector(queueTapped:)];
    self.navigationItem.rightBarButtonItem = queueButton;

    if (self.wantsSearch) {
        // Add a search ability.
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        // This will automatically set self.searchDisplayController.
        // However, due to some kind of bug with ARC, it doesn't get retained, so
        // I'm using a second property to hold ownership.
        self.searchController = [[UISearchDisplayController alloc]
                                 initWithSearchBar:searchBar
                                 contentsController:self];
        self.searchController.delegate = self;
        self.searchController.searchResultsDataSource = self;
        self.searchController.searchResultsDelegate = self;
        [self.searchController.searchResultsTableView registerNib:entryNib
                                           forCellReuseIdentifier:@"EntryCell"];
        self.tableView.tableHeaderView = searchBar;
    }
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Scroll down to hide the header.
    CGFloat headerHeight = self.tableView.tableHeaderView.frame.size.height;
    if (self.tableView.contentOffset.y < headerHeight) {
        self.tableView.contentOffset = CGPointMake(0, headerHeight);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EPBrowserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntryCell"];
    assert (cell != nil);
    if (!cell.playButton.gestureRecognizers.count) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(playTapped:)];
        [cell.playButton addGestureRecognizer:tapGesture];
    }
    BOOL useDateLabel = ((self.sortOrder==EPSortOrderAddDate ||
                          self.sortOrder==EPSortOrderPlayDate ||
                          self.sortOrder==EPSortOrderReleaseDate) && self.sections.count==1);
    if (!useDateLabel) {
        cell.dateLabel.text = nil;
    }
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSections;
    } else {
        data = self.sections;
    }
    [self updateCell:cell forIndexPath:indexPath withSections:data withDateLabel:useDateLabel];
    return cell;
}

- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel
{
    
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSectionTitles;
    } else {
        data = self.sectionTitles;
    }
    if (data != nil) {
        return [data count];
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSections;
    } else {
        data = self.sections;
    }
    if (data != nil) {
        return [[data objectAtIndex:section] count];
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
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSectionTitles;
    } else {
        data = self.sectionTitles;
    }
    return data[section];
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // Currently using same section titles for index titles.
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSectionTitles;
    } else {
        data = self.sectionTitles;
    }
    return data;
}


- (NSInteger)tableView:(UITableView *)tableView
sectionForSectionIndexTitle:(NSString *)title
               atIndex:(NSInteger)index
{
    // Section indicies are the same as index indicies.
    return index;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSectionTitles;
    } else {
        data = self.sectionTitles;
    }
    NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"TableSectionView"
                                                      owner:self
                                                    options:nil];
    EPTableSectionView *view = nibViews[0];
    view.sectionLabel.text = data[section];
    if (section == 0) {
        NSString *text;
        switch (self.sortOrder) {
            case EPSortOrderAlpha:
                text = @"Alphabetical";
                break;
            case EPSortOrderAddDate:
                text = @"Added Date";
                break;
            case EPSortOrderPlayDate:
                text = @"Play Date";
                break;
            case EPSortOrderReleaseDate:
                text = @"Release Date";
                break;
            case EPSortOrderManual:
                text = @"Manual";
                break;
        }
        view.sortDescriptionLabel.text = text;
    } else {
        view.sortDescriptionLabel.text = nil;
    }
    return view;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 23;
//}

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

/*****************************************************************************/
/* Searching                                                                 */
/*****************************************************************************/
- (void)filterContentForSearchText:(NSString *)searchText
{
    // Update filtered sections.
    NSPredicate *resultPred = [NSPredicate predicateWithFormat:@"%K contains[cd] %@",
                               self.filterPropertyName, searchText];
    NSMutableArray *newSections = [NSMutableArray arrayWithCapacity:self.sections.count];
    NSMutableArray *newSectionTitles = nil;
    if (self.sectionTitles != nil) {
        newSectionTitles = [NSMutableArray arrayWithCapacity:self.sectionTitles.count];
    }
    for (int i=0; i<self.sections.count; i++) {
        NSArray *section = self.sections[i];
        NSArray *newSection = [section filteredArrayUsingPredicate:resultPred];
        if (newSection.count) {
            [newSections addObject:newSection];
            if (newSectionTitles) {
                [newSectionTitles addObject:self.sectionTitles[i]];
            }
        }
    }
    self.filteredSections = newSections;
    self.filteredSectionTitles = newSectionTitles;
    
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
        shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


@end
