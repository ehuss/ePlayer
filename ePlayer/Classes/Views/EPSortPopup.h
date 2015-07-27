//
//  EPSortPopup.h
//  ePlayer
//
//  Created by Eric Huss on 7/26/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPCommon.h"

@interface EPSortPopup : UIView

@property (nonatomic) EPSortOrder sortOrder;
@property (nonatomic) id target;
@property (nonatomic) SEL action;
@property (nonatomic) UIView *blockingView;

@property (weak, nonatomic) IBOutlet UIButton *alphaButton;
@property (weak, nonatomic) IBOutlet UIButton *addDateButton;
@property (weak, nonatomic) IBOutlet UIButton *playDateButton;
@property (weak, nonatomic) IBOutlet UIButton *releaseDateButton;
@property (weak, nonatomic) IBOutlet UIButton *manualButton;

- (IBAction)alphaTouched:(id)sender;
- (IBAction)addDateTouched:(id)sender;
- (IBAction)playDateTouched:(id)sender;
- (IBAction)releaseDateTouched:(id)sender;
- (IBAction)manualTouched:(id)sender;

- (void)updateSelected;
- (void)setTarget:(id)target action:(SEL)action;

@end
