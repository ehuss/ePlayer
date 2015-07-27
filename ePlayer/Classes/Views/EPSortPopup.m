//
//  EPSortPopup.m
//  ePlayer
//
//  Created by Eric Huss on 7/26/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import "EPSortPopup.h"

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation EPSortPopup

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = YES;

        // I considered using a blurring background, but this seems good enough.
        // For future reference: iOS 8 added UIVisualEffectView which makes
        // it very easy to implement a blur view.  For iOS 7, Apple released
        // a UIImage category at WWDC to implement a blur.  See this for the
        // code: http://www.raywenderlich.com/84043/ios-8-visual-effects-tutorial
        self.blockingView = [[UIView alloc] initWithFrame:CGRectZero];
        self.blockingView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];

    }
    return self;
}

- (void)setTarget:(id)target action:(SEL)action
{
    self.target = target;
    self.action = action;
}

- (void)updateSelected
{
    self.alphaButton.selected = NO;
    self.addDateButton.selected = NO;
    self.playDateButton.selected = NO;
    self.releaseDateButton.selected = NO;
    self.manualButton.selected = NO;

    switch (self.sortOrder) {
        case EPSortOrderAlpha:
            self.alphaButton.selected = YES;
            break;
        case EPSortOrderAddDate:
            self.addDateButton.selected = YES;
            break;
        case EPSortOrderPlayDate:
            self.playDateButton.selected = YES;
            break;
        case EPSortOrderReleaseDate:
            self.releaseDateButton.selected = YES;
            break;
        case EPSortOrderManual:
            self.manualButton.selected = YES;
            break;
    }
}

- (IBAction)alphaTouched:(id)sender {
    self.sortOrder = EPSortOrderAlpha;
    [self updateSelected];
    [self.target performSelector:self.action withObject:self];
}

- (IBAction)addDateTouched:(id)sender {
    self.sortOrder = EPSortOrderAddDate;
    [self updateSelected];
    [self.target performSelector:self.action withObject:self];
}

- (IBAction)playDateTouched:(id)sender {
    self.sortOrder = EPSortOrderPlayDate;
    [self updateSelected];
    [self.target performSelector:self.action withObject:self];
}

- (IBAction)releaseDateTouched:(id)sender {
    self.sortOrder = EPSortOrderReleaseDate;
    [self updateSelected];
    [self.target performSelector:self.action withObject:self];
}

- (IBAction)manualTouched:(id)sender {
    self.sortOrder = EPSortOrderManual;
    [self updateSelected];
    [self.target performSelector:self.action withObject:self];
}

@end
