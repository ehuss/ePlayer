//
//  EPCommon.m
//  ePlayer
//
//  Created by Eric Huss on 4/16/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPCommon.h"

NSCalendar *gregorianCalendar;
UIPasteboard *playlistPasteboard;

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
        case EPSortOrderManual:
            return @"Manual";
        default:
            return @"Unknown";
    }
}

NSString *yearFromDate(NSDate *date)
{
    if (date==nil) {
        NSLog(@"nil date, please fix");
        return @"UNKNOWN";
    }
    NSDateComponents *comp = [gregorianCalendar components:NSCalendarUnitYear fromDate:date];
    return [NSString stringWithFormat:@"%li", (long)comp.year];
}

void createGregorianCalendar()
{
    gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}

// iOS 8 has introduced NSDateComponentsFormatter which supports
// localization.
NSString *formatDuration(NSTimeInterval interval)
{
    int i = interval;
//    int seconds = i % 60;
    int minutes = (i / 60) % 60;
    int hours = (i /3600);
    NSMutableArray *components = [NSMutableArray array];
    if (hours) {
        [components addObject:[NSString stringWithFormat:@"%ih", hours]];
    }
    if (minutes) {
        [components addObject:[NSString stringWithFormat:@"%im", minutes]];
    }
//    if (seconds) {
//        [components addObject:[NSString stringWithFormat:@"%is", seconds]];
//    }
    return [components componentsJoinedByString:@" "];
}
