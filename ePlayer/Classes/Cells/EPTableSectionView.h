//
//  EPTableHeaderView.h
//  ePlayer
//
//  Created by Eric Huss on 4/17/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPSortPopup.h"

@interface EPTableSectionView : UIView

@property (nonatomic) EPSortPopup *sortPopup;

@property (weak, nonatomic) IBOutlet UILabel *sortDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionLabel;

@end
