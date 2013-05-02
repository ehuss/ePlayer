//
//  EPBrowserCell.m
//  ePlayer
//
//  Created by Eric Huss on 4/17/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPBrowserCell.h"
#import "EPBrowseTableController.h"

@implementation EPBrowserCell

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

static CGFloat textViewOffset = 4.0;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    // Hide play button while editing.
    NSTimeInterval duration = animated ? 0.2 : 0;
    if (editing) {
        if (!self.playButton.hidden) {
            [UIView animateWithDuration:duration animations:^{
                self.playButton.hidden = YES;
                self.textView.center = CGPointMake(self.textView.center.x-self.playButton.frame.size.width+textViewOffset,
                                                    self.textView.center.y);
            }];
        }
    } else {
        self.textView.enabled = NO;
        if (self.playButton.hidden) {
            [UIView animateWithDuration:duration animations:^{
                self.playButton.hidden = NO;
                self.textView.center = CGPointMake(self.textView.center.x+self.playButton.frame.size.width-textViewOffset,
                                                    self.textView.center.y);
            }];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return self.parentController.renaming;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.parentController rename:self to:textField.text];
}

@end
