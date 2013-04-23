//
//  UIImage+EPCrop.m
//  ePlayer
//
//  Created by Eric Huss on 4/22/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "UIImage+EPCrop.h"

@implementation UIImage (EPCrop)

- (UIImage *)crop:(CGRect)rect
{
    rect = CGRectMake(rect.origin.x*self.scale,
                      rect.origin.y*self.scale,
                      rect.size.width*self.scale,
                      rect.size.height*self.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef
                                          scale:self.scale
                                    orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

@end