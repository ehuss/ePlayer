//
//  EPCommon.h
//  ePlayer
//
//  Created by Eric Huss on 4/16/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSArray+EPMap.h"
#import "EPMemoryDebug.h"
#import "UIView+EPUtil.h"
#import "RLMCollection+EPRealm.h"

typedef enum {
    EPSortOrderAlpha,
    EPSortOrderAddDate,
    EPSortOrderPlayDate,
    EPSortOrderReleaseDate,
    EPSortOrderManual
} EPSortOrder;

NSString *nameForSortOrder(EPSortOrder order);
NSString *yearFromDate(NSDate *date);
NSString *formatDuration(NSTimeInterval interval);

// Creating this is relatively expensive.
extern NSCalendar *gregorianCalendar;
void createGregorianCalendar(); // Called during app start.

// Settings keys.
extern NSString *EPSettingArtistsSortOrder;  // NSNumber EPSortOrder
extern NSString *EPSettingAllAbumsSortOrder;  // NSNumber EPSortOrder
extern NSString *EPSettingArtistAlbumsSortOrder;  // NSNumber EPSortOrder

extern UIPasteboard *playlistPasteboard;
