//
//  EPEditCell1.h
//  ePlayer
//
//  Created by Eric Huss on 4/23/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPEditCell1 : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *cutButton;
// Can't start name with "copy". :(
@property (weak, nonatomic) IBOutlet UIButton *cpyButton;
@property (weak, nonatomic) IBOutlet UIButton *pasteButton;

@end
