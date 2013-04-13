//
//  PlayerController.h
//  ePlayer
//
//  Created by Eric Huss on 4/12/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPPlayerController : UIViewController


@property (strong, nonatomic) UISlider *scrubber;
@property (strong, nonatomic) UIButton *prevButton;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) UIButton *playButton;
//@property (strong, nonatomic) UIButton *pauseButton;
@property (strong, nonatomic) UIButton *saveButton;
@end
