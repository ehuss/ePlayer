//
//  EPPlayerCellView.m
//  ePlayer
//
//  Created by Eric Huss on 4/13/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPPlayerCellView.h"


@implementation EPPlayerCellView

- (void)setCurrent:(BOOL)playing
{
    NSString *imageName;
    if (playing) {
        imageName = @"current-queue-item-playing";
    } else {
        imageName = @"current-queue-item-stopped";
    }
    self.currentItemView.image = [UIImage imageNamed:imageName];
}

- (void)unsetCurrent
{
    self.currentItemView.image = nil;
}

- (void)setEvenOdd:(BOOL)odd
{
    if (odd) {
        self.contentView.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0];
    } else {
        self.contentView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    }
}

// Introduced in iOS 8, this was interfering with the separatorInset value
// (I think the inset is essentially this plus separatorInset).
- (UIEdgeInsets)layoutMargins
{
    return UIEdgeInsetsZero;
}

@end
