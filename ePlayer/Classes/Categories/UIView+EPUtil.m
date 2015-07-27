//
//  UIView+EPUtil.m
//  ePlayer
//
//  Created by Eric Huss on 7/26/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import "UIView+EPUtil.h"

@implementation UIView (EPUtil)

- (CGFloat)ep_frame_x
{
    return self.frame.origin.x;
}

- (void)setEp_frame_x:(CGFloat)ep_frame_x
{
    CGRect frame = self.frame;
    frame.origin.x = ep_frame_x;
    self.frame = frame;
}

- (CGFloat)ep_frame_y
{
    return self.frame.origin.y;
}

- (void)setEp_frame_y:(CGFloat)ep_frame_y
{
    CGRect frame = self.frame;
    frame.origin.y = ep_frame_y;
    self.frame = frame;
}

- (CGFloat)ep_frame_width
{
    return self.frame.size.width;
}

- (void)setEp_frame_width:(CGFloat)ep_frame_width
{
    CGRect frame = self.frame;
    frame.size.width = ep_frame_width;
    self.frame = frame;
}

- (CGFloat)ep_frame_height
{
    return self.frame.size.height;
}

- (void)setEp_frame_height:(CGFloat)ep_frame_height
{
    CGRect frame = self.frame;
    frame.size.height = ep_frame_height;
    self.frame = frame;
}

- (CGSize)ep_frame_size
{
    return self.frame.size;
}

- (void)setEp_frame_size:(CGSize)ep_frame_size
{
    CGRect frame = self.frame;
    frame.size = ep_frame_size;
    self.frame = frame;
}

- (CGPoint)ep_frame_origin
{
    return self.frame.origin;
}

- (void)setEp_frame_origin:(CGPoint)ep_frame_origin
{
    CGRect frame = self.frame;
    frame.origin = ep_frame_origin;
    self.frame = frame;
}

@end
