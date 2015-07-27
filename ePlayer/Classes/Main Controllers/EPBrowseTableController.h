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
#import "EPPopupButton.h"
#import "EPRoot.h"
#import "EPEditToolbar.h"
#import "EPTableSectionView.h"

extern NSUInteger minEntriesForSections;

@interface EPBrowseTableController : UITableViewController
    <UISearchBarDelegate, UISearchDisplayDelegate, UITextFieldDelegate, UIActionSheetDelegate>
{
    BOOL _renaming;
    EPRoot *_root;
}

- (void)updateSections;

- (void)touchSortOrder:(EPSegmentedControl *)sender;
- (NSArray *)supportedSortOrders;
- (UITableViewCell *)createSortOrderCell;
- (void)rename:(EPBrowserCell *)cell to:(NSString *)newText;

@property (strong, nonatomic) EPFolder *folder;
@property (readonly, nonatomic) EPRoot *root;
@property (assign, nonatomic) BOOL focusAddFolder;

@property (assign, nonatomic)EPSortOrder sortOrder;
// Array of arrays.  The types of items depends on the subclass.
// The sections are passed to  "updateCell..." in order to set the cell content.
@property (strong, nonatomic) NSMutableArray *sections;
// sectionTitles is nil if there are no sections.
@property (strong, nonatomic) NSMutableArray *sectionTitles;
@property (nonatomic) NSMutableArray *sectionIndexTitles;
@property (readonly, nonatomic) EPPlayerController *playerController;
@property (assign, nonatomic) BOOL renaming;
@property (nonatomic) EPEditToolbar *editToolbar;
@property (nonatomic) EPTableSectionView *topSectionView;

// Searching.
@property (strong, nonatomic) UISearchDisplayController *searchController;
@property (strong, nonatomic) NSArray *filteredSections;
@property (strong, nonatomic) NSArray *filteredSectionTitles;
@property (nonatomic) NSArray *filteredSectionIndexTitles;
// When searching, the property in self.sections to look at.
@property (readonly, nonatomic) NSString *filterPropertyName;
@property (assign, nonatomic) BOOL wantsSearch;
@property (assign, nonatomic) BOOL indexesEnabled;
@property (strong, nonatomic) EPPopupButton *popupButton;
@end
