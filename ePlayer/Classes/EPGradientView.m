//
//  EPGradientView.m
//  ePlayer
//
//  Created by Eric Huss on 4/13/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation EPGradientView

- (void)awakeFromNib
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithWhite:0.10f alpha:1.0f] CGColor],
                       (id)[[UIColor colorWithWhite:0.05f alpha:1.0f] CGColor],
                       (id)[[UIColor colorWithWhite:0.10f alpha:1.0f] CGColor],
                       nil];
    [self.layer insertSublayer:gradient atIndex:0];
    [super awakeFromNib];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    // I don't 100% understand why this is necessary for subviews to lay out.
    [super layoutSublayersOfLayer:layer];
    // This is necessary because the gradient layer does not have auto constraints.
    CALayer *glayer = layer.sublayers[0];
    glayer.frame = layer.frame;
}

/* For reference, this does essentially the same thing.
   I have read that the performance may not be as good as CAGradientLayer.
   I cannot see any noticeable differences in banding that others observed.
*/
//- (void)drawRect:(CGRect)rect
//{
//    CGContextRef currentContext = UIGraphicsGetCurrentContext();
//    CGGradientRef gradient;
//    CGColorSpaceRef rgbColorspace;
//    size_t num_locations = 2;
//    CGFloat locations[2] = { 0.0, 1.0 };
//    CGFloat components[8] = { 1.0, 1.0, 1.0, 1.0,  // Start color
//        0.0, 0.0, 0.0, 1.0 }; // End color
//    
//    rgbColorspace = CGColorSpaceCreateDeviceRGB();
//    gradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
//    
//    CGRect currentBounds = self.bounds;
//    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
//    CGPoint bottomCenter = CGPointMake(CGRectGetMidX(currentBounds), currentBounds.size.height);
//    CGContextDrawLinearGradient(currentContext, gradient, topCenter, bottomCenter, 0);
//    
//    CGGradientRelease(gradient);
//    CGColorSpaceRelease(rgbColorspace);
//}

@end
