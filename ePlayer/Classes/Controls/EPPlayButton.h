//
//  EPPlayButton.h
//  ePlayer
//
//  Created by Eric Huss on 10/24/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EPBrowserCell;

@interface EPPlayButton : UIButton

@property (weak, nonatomic) IBOutlet EPBrowserCell *browserCell;

@end
