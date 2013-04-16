//
//  Folder.m
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "Folder.h"
#import "EPModels.h"


@implementation Folder

@dynamic sortOrder;
@dynamic entries;
// Note: NSManagedObject sets NS_REQUIRES_PROPERTY_DEFINTIONS, so automatic
// property synthesis is not available.
@synthesize sortedEntries = _sortedEntries;

- (NSArray *)sortedEntries
{
    if (_sortedEntries == nil) {
        NSString *key;
        BOOL ascending = NO;
        switch ([self.sortOrder intValue]) {
            case EPSortOrderAlpha:
                key = @"name";
                ascending = YES;
                break;
            case EPSortOrderAddDate:
                key = @"addDate";
                break;
            case EPSortOrderPlayDate:
                key = @"playDate";
                break;
            case EPSortOrderReleaseDate:
                key = @"releaseDate";
                break;
        }
        
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:key
                                                                   ascending:ascending];
        _sortedEntries = [self.entries sortedArrayUsingDescriptors:@[sortDesc]];
    }
    return _sortedEntries;
}

NSString *yearFromDate(NSDate *date)
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [cal components:NSYearCalendarUnit fromDate:date];
    return [NSString stringWithFormat:@"%i", comp.year];
}

- (NSString *)sectionTitleForEntry:(Entry *)entry;
{
    switch ([self.sortOrder intValue]) {
        case EPSortOrderAlpha:
            // Return first character of name.
            return [entry.name substringToIndex:1];

        case EPSortOrderAddDate:
            return yearFromDate(entry.addDate);

        case EPSortOrderPlayDate:
            return yearFromDate(entry.playDate);

        case EPSortOrderReleaseDate:
            return yearFromDate(entry.releaseDate);
    }
    [NSException raise:@"UnknownSortOrder" format:@"Unknown sort order %i.", [self.sortOrder intValue]];
    return nil; // Silence warning.
}

@end
