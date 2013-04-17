//
//  EPSortOrderController.h
//  ePlayer
//
//  Created by Eric Huss on 4/15/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPCommon.h"

@interface EPSortOrderController : UITableViewController

@property (assign, nonatomic) EPSortOrder currentSortOrder;
// Previous controller index in the tab bar.
@property (assign, nonatomic) NSUInteger previousControllerIndex;

@end
