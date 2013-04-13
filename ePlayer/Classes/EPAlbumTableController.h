//
//  EPArtistAlbumTableController.h
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EPAlbumTableController : UITableViewController

- (void)loadAllAlbums;

@property (nonatomic, strong) NSArray *albums;
@end
