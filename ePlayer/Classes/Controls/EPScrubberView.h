//
//  EPScrubberView.h
//  ePlayer
//
//  Created by Eric Huss on 4/12/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPScrubberView : UISlider

@property (assign, nonatomic, readonly) float scrubbingSpeed;
@property (strong, nonatomic) NSArray *scrubbingSpeeds;
@property (strong, nonatomic) NSArray *scrubbingSpeedChangePositions;
@property (strong, nonatomic) UILabel *speedLabel;

@end
