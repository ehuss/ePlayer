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

extern NSUInteger minEntriesForSections;

@interface EPBrowseTableController : UITableViewController

@property (assign, nonatomic)EPSortOrder sortOrder;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *sectionTitles;

@end
