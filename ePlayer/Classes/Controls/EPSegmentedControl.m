//
//  EPSegmentedControl.m
//  ePlayer
//
//  Created by Eric Huss on 4/18/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPSegmentedControl.h"

@implementation EPSegmentedControl

- (id)initWithItems:(NSArray *)items frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.items = items;
        self.selectedSegmentIndex = EPSegmentControlNoSegment;
        self.opaque = NO;
        [self loadImages];
    }
    return self;
}

- (void)loadImages
{
    self.leftNormal = [[UIImage imageNamed:@"segmented-left-normal"]
                       resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    self.middleNormal = [UIImage imageNamed:@"segmented-middle-normal"];
    self.rightNormal = [[UIImage imageNamed:@"segmented-right-normal"]
                        resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    self.dividerNormal =[UIImage imageNamed:@"segmented-divider-normal"];

    self.leftSelected = [[UIImage imageNamed:@"segmented-left-selected"]
                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    self.middleSelected = [UIImage imageNamed:@"segmented-middle-selected"];
    self.rightSelected = [[UIImage imageNamed:@"segmented-right-selected"]
                          resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    self.dividerSelected =[UIImage imageNamed:@"segmented-divider-selected"];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint pos = [touch locationInView:self];
    CGFloat width = self.frame.size.width/self.items.count;
    int index = ((int)pos.x)/(int)width;
    if (index != self.selectedSegmentIndex) {
        self.selectedSegmentIndex = index;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
        [self setNeedsDisplay];
    }
    return NO;
}

- (void)segmentTapped:(id)sender
{
    UIButton *button = sender;
    self.selectedSegmentIndex = button.tag;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat currentX = 0;
    CGFloat fullWidth = self.frame.size.width/self.items.count;
    CGFloat width;
    CGFloat offsetX;
    CGFloat dividerWidth = self.dividerSelected.size.width/2.0f;
    UIImage *image;
    UIImage *divider;
    [[UIColor whiteColor] set];
    UIFont *font = [UIFont boldSystemFontOfSize:14];
    for (int i=0; i<self.items.count; i++) {
        NSString *text = self.items[i];
        if (i==0) {
            if (i==self.selectedSegmentIndex) {
                image = self.leftSelected;
                divider = self.dividerSelected;
            } else {
                image = self.leftNormal;
            }
            width = fullWidth-dividerWidth;
            offsetX = 0;
        } else if (i==self.items.count-1) {
            if (i==self.selectedSegmentIndex) {
                image = self.rightSelected;
            } else {
                image = self.rightNormal;
            }
            width = fullWidth-2.0f*dividerWidth;
            offsetX = dividerWidth;
        } else {
            if (i==self.selectedSegmentIndex) {
                image = self.middleSelected;
            } else {
                image = self.middleNormal;
            }
            width = fullWidth-dividerWidth;
            offsetX = dividerWidth;
        }
        [image drawInRect:CGRectMake(currentX+offsetX, 0, width, image.size.height)];
        if (self.selectedSegmentIndex == i || self.selectedSegmentIndex == i+1) {
            divider = self.dividerSelected;
        } else {
            divider = self.dividerNormal;
        }
        // Dividers are drawn to the right.
        if (i!=self.items.count-1) {
            [divider drawInRect:CGRectMake(currentX+fullWidth-dividerWidth, 0,
                                           divider.size.width, divider.size.height)];
        }
        // Draw the label.
        CGContextSaveGState(context);
        CGContextSetShadow(context, CGSizeMake(0, -1), 0);
        CGSize size = [text sizeWithFont:font
                       constrainedToSize:CGSizeMake(fullWidth-2, image.size.height)];
        [text drawInRect:CGRectMake(currentX+1, (image.size.height-size.height)/2.0f,
                                    fullWidth-2, size.height)
                withFont:font
           lineBreakMode:NSLineBreakByWordWrapping
               alignment:NSTextAlignmentCenter];
        CGContextRestoreGState(context);
        currentX += fullWidth;
    }
}



@end
