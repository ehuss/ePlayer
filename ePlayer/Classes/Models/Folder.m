//
//  Folder.m
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "Folder.h"
#import "EPCommon.h"

@interface Folder ()
{
    EPSortOrder _sortedEntriesOrder;
}
@end

@implementation Folder

@dynamic sortOrder;
@dynamic entries;

// Note: NSManagedObject sets NS_REQUIRES_PROPERTY_DEFINTIONS, so automatic
// property synthesis is not available.
@synthesize sortedEntries = _sortedEntries;

- (NSArray *)sortedEntries
{
    if (_sortedEntries == nil || _sortedEntriesOrder != [self.sortOrder intValue]) {
        if ([self.sortOrder intValue] == EPSortOrderManual) {
            _sortedEntries = self.entries.array;
        } else {
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
            
            _sortedEntries = [self.entries sortedArrayUsingComparator:^(Entry *obj1, Entry *obj2) {
                if (ascending) {
                    return [[obj1 valueForKey:key] compare:[obj2 valueForKey:key]];
                } else {
                    return [[obj2 valueForKey:key] compare:[obj1 valueForKey:key]];
                }
            }];
        }
        _sortedEntriesOrder = [self.sortOrder intValue];
    }
    return _sortedEntries;
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

// Working around a bug in Core Data's auto-generated code.
// This was raising an exception (set argument is not an NSSet).
// See http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors
- (void)addEntriesObject:(Entry *)value
{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.entries];
    [tempSet addObject:value];
    self.entries = tempSet;
}


@end
