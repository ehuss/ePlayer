//
//  UIView+EPUtil.h
//  ePlayer
//
//  Created by Eric Huss on 7/26/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (EPUtil)

@property (nonatomic) CGFloat ep_frame_x;
@property (nonatomic) CGFloat ep_frame_y;
@property (nonatomic) CGFloat ep_frame_width;
@property (nonatomic) CGFloat ep_frame_height;
@property (nonatomic) CGPoint ep_frame_origin;
@property (nonatomic) CGSize ep_frame_size;

@end
