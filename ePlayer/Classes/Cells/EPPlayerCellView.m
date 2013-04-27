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
        self.evenOddBackgroundView.image = [UIImage imageNamed:@"player-cell-light"];
    } else {
        self.evenOddBackgroundView.image = [UIImage imageNamed:@"player-cell-dark"];
    }
}

@end
