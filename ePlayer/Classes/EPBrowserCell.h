//
//  EPBrowserCell.h
//  ePlayer
//
//  Created by Eric Huss on 4/17/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPBrowserCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *labelView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end
