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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    // Hide play button while editing.
    if (editing) {
        if (!self.playButton.hidden) {
            [self togglePlayVisibility];
        }
    } else {
        self.textView.enabled = NO;
        if (self.playButton.hidden) {
            [self togglePlayVisibility];
        }
    }
}

- (void)togglePlayVisibility
{
    // Unfortunately I was unable to get the IBOutlet for this constraint to
    // load (it was always nil).  Just iterate to find it.
    //
    // It would be nice if this could be animated, but just sticking it in an
    // animation block doesn't do anything.
    for (NSLayoutConstraint *constraint in self.playButton.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeWidth) {
            if (constraint.constant == 0) {
                constraint.constant = 44;
                self.playButton.hidden = NO;
            } else {
                constraint.constant = 0;
                self.playButton.hidden = YES;
            }
            break;
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
