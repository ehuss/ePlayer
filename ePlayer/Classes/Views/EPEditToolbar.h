//
//  EPEditToolbar.h
//  ePlayer
//
//  Created by Eric Huss on 12/27/14.
//  Copyright (c) 2014 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPEditToolbar : UIView
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *cutButton;
@property (weak, nonatomic) IBOutlet UIButton *cpyButton;
@property (weak, nonatomic) IBOutlet UIButton *pasteButton;
@property (weak, nonatomic) IBOutlet UIButton *renameButton;
@property (weak, nonatomic) IBOutlet UIButton *addFolderButton;
@property (weak, nonatomic) IBOutlet UIButton *collapseButton;

@end
