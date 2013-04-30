//
//  Folder.m
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#import "Folder.h"
#import "EPCommon.h"

@implementation Folder

@dynamic sortOrder;
@dynamic entries;

// Note: NSManagedObject sets NS_REQUIRES_PROPERTY_DEFINTIONS, so automatic
// property synthesis is not available.  You must @synthensize any new properties.

- (Folder *)clone
{
    Folder *folder = (Folder *)[NSEntityDescription insertNewObjectForEntityForName:@"Folder"
                                                             inManagedObjectContext:self.managedObjectContext];
    folder.name = [NSString stringWithFormat:@"%@ Copy", self.name];
    folder.sortOrder = self.sortOrder;
    folder.addDate = [NSDate date];
    folder.releaseDate = self.releaseDate;
    folder.playDate = self.playDate;
    folder.playCount = self.playCount;
    folder.entries = self.entries;
    return folder;
}

- (NSArray *)sortedEntries
{
    if ([self.sortOrder intValue] == EPSortOrderManual) {
        // Already in correct sort order.
        return self.entries.array;
    } else {
        if ([self.sortOrder intValue] == EPSortOrderAlpha) {
            return [self.entries sortedArrayUsingComparator:^(Entry *obj1, Entry *obj2) {
                return [obj1.name localizedCaseInsensitiveCompare:obj2.name];
            }];
        } else {
            // Date sorting.
            SEL s;
            switch ([self.sortOrder intValue]) {
                case EPSortOrderAddDate:
                    s = @selector(addDate);
                    break;
                case EPSortOrderPlayDate:
                    s = @selector(playDate);
                    break;
                case EPSortOrderReleaseDate:
                    s = @selector(releaseDate);
                    break;
            }
            return [self.entries sortedArrayUsingComparator:^(Entry *obj1, Entry *obj2) {
                // Descending order.
                return [[obj2 performSelector:s] compare:[obj1 performSelector:s]];
            }];
        }
    }
}


- (NSString *)sectionTitleForEntry:(Entry *)entry;
{
    switch ([self.sortOrder intValue]) {
        case EPSortOrderAlpha:
            // Return first character of name.
            return [entry.name substringToIndex:1];

        case EPSortOrderAddDate:
            if ([entry.addDate compare:[NSDate distantPast]] == NSOrderedSame) {
                return @"Unknown";
            } else {
                return yearFromDate(entry.addDate);
            }

        case EPSortOrderPlayDate:
            if ([entry.playDate compare:[NSDate distantPast]] == NSOrderedSame) {
                return @"Never";
            } else {
                return yearFromDate(entry.playDate);
            }

        case EPSortOrderReleaseDate:
            if ([entry.releaseDate compare:[NSDate distantPast]] == NSOrderedSame) {
                return @"Unknown";
            } else {
                return yearFromDate(entry.releaseDate);
            }
    }
    [NSException raise:@"UnknownSortOrder" format:@"Unknown sort order %i.", [self.sortOrder intValue]];
    return nil; // Silence warning.
}

@end
