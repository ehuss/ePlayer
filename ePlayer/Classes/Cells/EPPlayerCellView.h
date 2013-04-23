//
//  EPPlayerCellView.h
//  ePlayer
//
//  Created by Eric Huss on 4/13/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPPlayerCellView : UIView

- (void)setCurrent:(BOOL)playing;
- (void)unsetCurrent;

@property (strong, nonatomic) UILabel *queueNumLabel;
@property (strong, nonatomic) UILabel *trackNameLabel;
@property (strong, nonatomic) UILabel *trackTimeLabel;
@property (strong, nonatomic) UIImageView *currentItemView;

@end
