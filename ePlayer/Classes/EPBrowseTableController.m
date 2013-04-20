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

- (BOOL)wantsSearch
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // This seems to be bugged in Interface Builder.
    self.tableView.sectionIndexMinimumDisplayRowCount = 10;
    // Need this for a complex issue.  When bringing up the queue, the bottom
    // tab bar is hidden.  When returning to this table, it gets resized as
    // the tab bar is brought back.  This causes the contentOffset to get reset
    // if the table does not fill the entire screen.  That causes the search
    // header to pop back (if it was hidden).  There might be some way
    // to set this in Interface Builder, but I couldn't find it.
    self.tableView.autoresizingMask = 0;
    // Register the class for creating cells.
    UINib *entryNib = [UINib nibWithNibName:@"EntryCell" bundle:nil];
    [self.tableView registerNib:entryNib
         forCellReuseIdentifier:@"EntryCell"];
    
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

        // Scroll down to hide the header.
        CGFloat headerHeight = searchBar.frame.size.height;
        self.tableView.contentOffset = CGPointMake(0, headerHeight);
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    if (self.hasSortCell && indexPath.section==0 && indexPath.row==0) {
        // Sort order cell.
        //            NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"SortCell"
        //                                                              owner:self
        //                                                            options:nil];
        //            UITableViewCell *cell = nibViews[0];
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:@"SortCell"];
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
        int selectedIndex = 0;
        NSArray *supportedSortOrders = [self supportedSortOrders];
        for (int i=0; i<supportedSortOrders.count; i++) {
            EPSortOrder so = [[supportedSortOrders objectAtIndex:i] intValue];
            switch (so) {
                case EPSortOrderAlpha:
                    [items addObject:@"Alpha"];
                    break;
                case EPSortOrderAddDate:
                    [items addObject:@"Add\nDate"];
                    break;
                case EPSortOrderPlayDate:
                    [items addObject:@"Play\nDate"];
                    break;
                case EPSortOrderReleaseDate:
                    [items addObject:@"Release\nDate"];
                    break;
                case EPSortOrderManual:
                    [items addObject:@"Manual"];
                    break;
            }
            if (so == self.sortOrder) {
                selectedIndex = i;
            }
        }
        EPSegmentedControl *seg = [[EPSegmentedControl alloc] initWithItems:items
                                                                      frame:cell.frame];
        seg.selectedSegmentIndex = selectedIndex;
        [seg addTarget:self action:@selector(touchSortOrder:) forControlEvents:UIControlEventValueChanged];
        [cell addSubview:seg];
        //            UISegmentedControl *seg = (UISegmentedControl *)[cell viewWithTag:1];
        //            NSDictionary *attrs = @{UITextAttributeFont: [UIFont systemFontOfSize:10]};
        //            [seg setTitleTextAttributes:attrs forState:UIControlStateNormal];
        return cell;
    }
    if (self.hasInsertCell) {
        if ((self.hasSortCell && indexPath.section==0 && indexPath.row == 1) ||
            (!self.hasSortCell && indexPath.section==0 && indexPath.row==0)) {
            // Special "insert" cell.
            NSArray *nibViews = [[NSBundle mainBundle] loadNibNamed:@"InsertCell"
                                                              owner:self
                                                            options:nil];
            UITableViewCell *cell = nibViews[0];
            return cell;
        }
    }
    
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
    if (indexPath.section == 0) {
        // Adjust index path for the added cells.
        if (self.hasSortCell) {
            indexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
        }
        if (self.hasInsertCell) {
            indexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
        }
    }
    [self updateCell:cell forIndexPath:indexPath withSections:data withDateLabel:useDateLabel];
    return cell;
}

- (void)touchSortOrder:(EPSegmentedControl *)sender
{
    self.hasSortCell = NO;
    if (self.editing) {
        [self setEditing:NO animated:YES];
    }
    self.sortOrder = [[[self supportedSortOrders] objectAtIndex:sender.selectedSegmentIndex] intValue];
}

//- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (self.hasInsertCell && indexPath.section==0 && indexPath.row==0) {
//        return 30;
//    } else {
//        return 44;
//    }
//    
//}

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
    NSInteger count;
    if (data != nil && data.count) {
        count = [[data objectAtIndex:section] count];
    } else {
        count = 0;
    }
    if (self.hasInsertCell && section == 0) {
        count += 1;
    }
    if (self.hasSortCell && section == 0) {
        count += 1;
    }
    return count;
}

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
    if (!data) {
        return nil;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSArray *data;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        data = self.filteredSectionTitles;
    } else {
        data = self.sectionTitles;
    }
    if (data) {
        return 23;
    } else {
        return 0;
    }
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

- (EPPlayerController *)playerController
{
    return self.tabBarController.viewControllers[3];
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
