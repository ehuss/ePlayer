//
//  EPInfoPopup.h
//  ePlayer
//
//  Created by Eric Huss on 7/28/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

// This shouldn't be a class, but could be useful for later.
@interface EPInfoPopup : UIView

+ (void)showPopupWithText:(NSString *)text inView:(UIView *)view;

@end
