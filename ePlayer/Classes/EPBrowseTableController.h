//
//  EPBrowseTableController.h
//  ePlayer
//
//  Created by Eric Huss on 4/14/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPCommon.h"
#import "EPBrowserCell.h"
#import "EPPlayerController.h"
#import "EPSegmentedControl.h"

extern NSUInteger minEntriesForSections;

@interface EPBrowseTableController : UITableViewController
    <UISearchBarDelegate, UISearchDisplayDelegate, UITextFieldDelegate>

- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel;

- (void)touchSortOrder:(EPSegmentedControl *)sender;
- (NSArray *)supportedSortOrders;
- (UITableViewCell *)createSortOrderCell;

@property (assign, nonatomic)EPSortOrder sortOrder;
// Array of arrays.  The types of items depends on the subclass.
// The sections are passed to  "updateCell..." in order to set the cell content.
@property (nonatomic, strong) NSMutableArray *sections;
// sectionTitles is nil if there are no sections.
@property (nonatomic, strong) NSMutableArray *sectionTitles;
@property (nonatomic, readonly) EPPlayerController *playerController;
// Control cells are the ones at the top used for setting sort order,
// inserting rows, etc.
@property (nonatomic, strong) NSArray *controlCells;
@property (nonatomic, assign) BOOL showingControlCells;

// Searching.
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSArray *filteredSections;
@property (nonatomic, strong) NSArray *filteredSectionTitles;
// When searching, the property in self.sections to look at.
@property (nonatomic, readonly) NSString *filterPropertyName;
@property (nonatomic, assign) BOOL wantsSearch;
@property (nonatomic, assign) BOOL indexesEnabled;
@end
