//
//  EPUpdateResultsController.h
//  ePlayer
//
//  Created by Eric Huss on 5/6/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>


// This is used by the database update feature to display information about
// what has been updated.
@interface EPUpdateResultsController : UIViewController

@property (strong, nonatomic) NSString *results;
@end
