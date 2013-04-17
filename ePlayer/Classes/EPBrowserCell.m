//
//  EPBrowserCell.m
//  ePlayer
//
//  Created by Eric Huss on 4/17/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPBrowserCell.h"

@implementation EPBrowserCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
