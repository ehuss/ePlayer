//
//  EPInfoPopup.m
//  ePlayer
//
//  Created by Eric Huss on 7/28/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import "EPInfoPopup.h"
#import "UIView+EPUtil.h"

@implementation EPInfoPopup

+ (void)showPopupWithText:(NSString *)text inView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.layer.cornerRadius = 5;
    label.layer.masksToBounds = YES;
    label.text = text;
    [label sizeToFit];
    label.ep_frame_height += 10;
    label.ep_frame_width += 10;
    label.center = view.center;
    [view addSubview:label];
    [UIView animateWithDuration:2.0 delay:2.0 options:0 animations:^{
        label.alpha = 0;
    } completion:^(BOOL finished) {
        [label removeFromSuperview];
    }];
}

@end
