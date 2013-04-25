//
//  EPArtistTableController.h
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPLibTableController.h"

@interface EPArtistTableController : EPLibTableController

// Array of MPMediaItemCollection.
@property (nonatomic, strong) NSArray *artists;
@end
