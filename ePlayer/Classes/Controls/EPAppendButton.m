//
//  EPAppendButton.m
//  ePlayer
//
//  Created by Eric Huss on 4/23/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPAppendButton.h"

@implementation EPAppendButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
        self.backgroundColor = nil;
        [self setTitle:@"Append" forState:UIControlStateNormal];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.shadowColor = [UIColor darkGrayColor];
        self.titleLabel.shadowOffset = CGSizeMake(0, -2);
        self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        UIImage *background = [UIImage imageNamed:@"append-popout"];
        background = [background resizableImageWithCapInsets:UIEdgeInsetsMake(10, 23, 10, 10)];
        [self setBackgroundImage:background forState:UIControlStateNormal];
    }
    return self;
}

@end
