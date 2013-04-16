//
//  EPPlayerCellView.m
//  ePlayer
//
//  Created by Eric Huss on 4/13/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPPlayerCellView.h"

@implementation EPPlayerCellView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
        
        self.queueNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 11, 52, 21)];
        self.queueNumLabel.font = [UIFont boldSystemFontOfSize:17.0];
        self.queueNumLabel.textColor = [UIColor whiteColor];
        self.queueNumLabel.opaque = NO;
        self.queueNumLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.queueNumLabel];

        self.trackNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 11, 192, 21)];
        self.trackNameLabel.font = [UIFont boldSystemFontOfSize:17.0];
        self.trackNameLabel.textColor = [UIColor whiteColor];
        self.trackNameLabel.opaque = NO;
        self.trackNameLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.trackNameLabel];
        
        self.trackTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(264, 11, 52, 21)];
        self.trackTimeLabel.font = [UIFont boldSystemFontOfSize:17.0];
        self.trackTimeLabel.textAlignment = NSTextAlignmentRight;
        self.trackTimeLabel.textColor = [UIColor whiteColor];
        self.trackTimeLabel.opaque = NO;
        self.trackTimeLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.trackTimeLabel];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // Use the same color and width as the default cell separator for now
    CGContextSetRGBStrokeColor(ctx, 0.3, 0.3, 0.3, 1.0);
    CGContextSetLineWidth(ctx, 1.0);
    
    CGContextMoveToPoint(ctx, 60, 0);
    CGContextAddLineToPoint(ctx, 60, self.bounds.size.height);
    CGContextMoveToPoint(ctx, 260, 0);
    CGContextAddLineToPoint(ctx, 260, self.bounds.size.height);
    
    CGContextStrokePath(ctx);
}

- (void)setCurrent:(BOOL)playing
{
    NSString *imageName;
    if (playing) {
        imageName = @"current-queue-item-playing";
    } else {
        imageName = @"current-queue-item-stopped";
    }
    self.currentItemView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    [self.currentItemView sizeToFit];
    self.currentItemView.center = CGPointMake(55, 22);
    [self addSubview:self.currentItemView];
}

- (void)unsetCurrent
{
    [self.currentItemView removeFromSuperview];
}

@end
