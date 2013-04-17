//
//  EPCommon.m
//  ePlayer
//
//  Created by Eric Huss on 4/16/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPCommon.h"

NSCalendar *gregorianCalendar;

NSString *EPSettingArtistsSortOrder = @"artistsSortOrder";
NSString *EPSettingAllAbumsSortOrder = @"allAlbumsSortOrder";
NSString *EPSettingArtistAlbumsSortOrder = @"artistAlbumsSortOrder";

NSString *nameForSortOrder(EPSortOrder order)
{
    switch (order) {
        case EPSortOrderAlpha:
            return @"Alphabetical";
        case EPSortOrderAddDate:
            return @"Added Date";
        case EPSortOrderPlayDate:
            return @"Play Date";
        case EPSortOrderReleaseDate:
            return @"Release Date";
        default:
            return @"Unknown";
    }
}

NSString *yearFromDate(NSDate *date)
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [cal components:NSYearCalendarUnit fromDate:date];
    return [NSString stringWithFormat:@"%i", comp.year];
}

void createGregorianCalendar()
{
    gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
}
