//
//  EPLyricView.h
//  ePlayer
//
//  Created by Eric Huss on 4/27/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPCommon.h"

@interface EPLyricView : UITextView

- (void)updateWithSong:(Song *)song;

@end
