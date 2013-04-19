//
//  EPBrowserCell.m
//  ePlayer
//
//  Created by Eric Huss on 4/17/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPBrowserCell.h"

@implementation EPBrowserCell

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    NSTimeInterval duration = animated ? 0.2 : 0;
    if (editing) {
        [UIView animateWithDuration:duration animations:^{
            self.playButton.hidden = YES;
            self.labelView.center = CGPointMake(self.labelView.center.x-self.playButton.frame.size.width,
                                                self.labelView.center.y);
        }];
    } else {
        if (self.playButton.hidden) {
            [UIView animateWithDuration:duration animations:^{
                self.playButton.hidden = NO;
                self.labelView.center = CGPointMake(self.labelView.center.x+self.playButton.frame.size.width,
                                                    self.labelView.center.y);
            }];
        }
    }
}

@end
