//
//  EPPlayerCellView.h
//  ePlayer
//
//  Created by Eric Huss on 4/13/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPPlayerCellView : UITableViewCell

- (void)setCurrent:(BOOL)playing;
- (void)unsetCurrent;
- (void)setEvenOdd:(BOOL)odd;

@property (weak, nonatomic) IBOutlet UILabel *queueNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *currentItemView;

@end
