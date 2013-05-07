//
//  EPStretchButton.m
//  ePlayer
//
//  Created by Eric Huss on 5/6/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPStretchButton.h"

@implementation EPStretchButton

- (void)awakeFromNib
{
    [self fixStretchableImages];
}

- (void)fixStretchableImages
{
    [self fixStretchableImage:UIControlStateNormal];
//    [self fixStretchableImage:UIControlStateHighlighted];
//    [self fixStretchableImage:UIControlStateDisabled];
//    [self fixStretchableImage:UIControlStateSelected];
}

- (void)fixStretchableImage:(UIControlState)state
{
    if (_bgImageName != nil) {
        UIImage *image = [UIImage imageNamed:_bgImageName];
        image = [image resizableImageWithCapInsets:_bgInsets];
        [self setBackgroundImage:image forState:state];
    }
}


@end
