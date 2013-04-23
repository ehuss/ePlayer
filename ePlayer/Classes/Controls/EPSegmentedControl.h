//
//  EPSegmentedControl.h
//  ePlayer
//
//  Created by Eric Huss on 4/18/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    EPSegmentControlNoSegment = -1
};

/*
 Call addTarget:action:forControlEvents:UIControlEventValueChanged to get changes.
 */
@interface EPSegmentedControl : UIControl

- (id)initWithItems:(NSArray *)items frame:(CGRect)frame;

@property (strong, nonatomic) NSArray *items;
@property (assign, nonatomic) NSInteger selectedSegmentIndex;

@property (strong, nonatomic) UIImage *leftNormal;
@property (strong, nonatomic) UIImage *leftSelected;
@property (strong, nonatomic) UIImage *middleNormal;
@property (strong, nonatomic) UIImage *middleSelected;
@property (strong, nonatomic) UIImage *rightNormal;
@property (strong, nonatomic) UIImage *rightSelected;
@property (strong, nonatomic) UIImage *dividerNormal;
@property (strong, nonatomic) UIImage *dividerSelected;



@end
