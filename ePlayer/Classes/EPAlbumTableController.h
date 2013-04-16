//
//  EPArtistAlbumTableController.h
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPBrowseTableController.h"

@interface EPAlbumTableController : EPBrowseTableController

@property (nonatomic, strong) NSArray *albums;
@property (nonatomic, strong) UILocalizedIndexedCollation *collation;
@property (nonatomic, strong) NSMutableArray *sections;
@end
