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
#import "EPPopupButton.h"
#import "EPRoot.h"
#import "EPEditToolbar.h"
#import "EPTableSectionView.h"

extern NSUInteger minEntriesForSections;

@interface EPBrowseTableController : UITableViewController
    <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating,
     UITextFieldDelegate, UIActionSheetDelegate>
{
    BOOL _renaming;
    EPRoot *_root;
}

- (void)updateSections;

- (void)rename:(EPBrowserCell *)cell to:(NSString *)newText;

@property (nonatomic) EPFolder *folder;
@property (nonatomic) EPRoot *root;
@property (nonatomic) BOOL focusAddFolder;
@property (nonatomic, readonly) BOOL isRootFolder;

@property (assign, nonatomic)EPSortOrder sortOrder;
// Array of arrays of EPEntry objects.
// Sections segregate the entries based on the sorting type
// (alpha uses the first letter of each name, others use years for date).
@property (strong, nonatomic) NSMutableArray *sections;
// sectionTitles is nil if there are no sections.
@property (strong, nonatomic) NSMutableArray *sectionTitles;
@property (nonatomic) NSMutableArray *sectionIndexTitles;
@property (readonly, nonatomic) EPPlayerController *playerController;
@property (assign, nonatomic) BOOL renaming;
@property (nonatomic) EPEditToolbar *editToolbar;
@property (nonatomic) EPTableSectionView *topSectionView;

// Searching.
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSArray *filteredSections;
@property (strong, nonatomic) NSArray *filteredSectionTitles;
@property (nonatomic) NSArray *filteredSectionIndexTitles;
// When searching, the property in self.sections to look at.
@property (readonly, nonatomic) NSString *filterPropertyName;
@property (assign, nonatomic) BOOL wantsSearch;
@property (assign, nonatomic) BOOL indexesEnabled;
@property (strong, nonatomic) EPPopupButton *popupButton;
@end
