//
//  EPGearTableController.h
//  ePlayer
//
//  Created by Eric Huss on 5/6/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPGearTableController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *iPodSwitch;
- (IBAction)iPodSwitchChanged:(id)sender;

@end
