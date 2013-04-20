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
    <UISearchBarDelegate, UISearchDisplayDelegate>

- (void)updateCell:(EPBrowserCell *)cell
      forIndexPath:(NSIndexPath *)indexPath
      withSections:(NSArray *)sections
     withDateLabel:(BOOL)useDateLabel;

- (void)touchSortOrder:(EPSegmentedControl *)sender;

- (NSArray *)supportedSortOrders;

@property (assign, nonatomic)EPSortOrder sortOrder;
@property (nonatomic, strong) NSArray *sections;
// sectionTitles is nil if there are no sections.
@property (nonatomic, strong) NSMutableArray *sectionTitles;
@property (nonatomic, readonly) EPPlayerController *playerController;
@property (nonatomic, assign) BOOL hasInsertCell;
@property (nonatomic, assign) BOOL hasSortCell;

// Searching.
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSArray *filteredSections;
@property (nonatomic, strong) NSArray *filteredSectionTitles;
@property (nonatomic, readonly) NSString *filterPropertyName;
@property (nonatomic, readonly) BOOL wantsSearch;
@end
