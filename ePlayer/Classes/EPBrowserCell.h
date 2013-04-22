//
//  EPBrowserCell.h
//  ePlayer
//
//  Created by Eric Huss on 4/17/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EPBrowseTableController;

@interface EPBrowserCell : UITableViewCell <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) EPBrowseTableController *parentController;

@end
