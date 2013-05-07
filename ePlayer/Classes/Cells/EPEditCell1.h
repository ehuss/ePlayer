//
//  EPEditCell1.h
//  ePlayer
//
//  Created by Eric Huss on 4/23/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPStretchButton.h"

@interface EPEditCell1 : UITableViewCell
@property (weak, nonatomic) IBOutlet EPStretchButton *deleteButton;
@property (weak, nonatomic) IBOutlet EPStretchButton *cutButton;
// Can't start name with "copy". :(
@property (weak, nonatomic) IBOutlet EPStretchButton *cpyButton;
@property (weak, nonatomic) IBOutlet EPStretchButton *pasteButton;
@property (weak, nonatomic) IBOutlet EPStretchButton *gearButton;

@end
