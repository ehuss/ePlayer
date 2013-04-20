//
//  EPArtistAlbumTableController.h
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPLibTableController.h"

@interface EPAlbumTableController : EPLibTableController

// Sections contain EPMediaItemWrappers.
// Array of MPMediaItemCollections.
@property (strong, nonatomic) NSArray *albums;
@property (assign, nonatomic) BOOL isGlobalAlbums;
@end
