//
//  EPRFolder.m
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import "EPRFolder.h"

@implementation EPRFolder

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"sortOrder": @0,
             @"entries": @[],
             @"uuid": [NSUUID UUID].UUIDString,
             @"duration": @0};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

/*****************************************************************************/
#pragma mark - Class methods
/*****************************************************************************/
+ (EPRFolder *)folderWithName:(NSString *)name
                    sortOrder:(EPSortOrder)sortOrder
                  releaseDate:(NSDate *)releaseDate
                      addDate:(NSDate *)addDate
                     playDate:(NSDate *)playDate
{
    EPRFolder *folder = [[EPRFolder alloc] init];
    folder.name = name;
    folder.sortOrder = sortOrder;
    folder.releaseDate = releaseDate;
    folder.addDate = addDate;
    folder.playDate = playDate;
    return folder;
}

/*****************************************************************************/
#pragma mark - Misc
/*****************************************************************************/

- (void)incrementDuration:(NSTimeInterval)duration
{
    self.duration += duration;
    for (EPRFolder *parent in self.parents) {
        [parent incrementDuration:duration];
    }
}

- (NSURL *)url
{
    NSString *s = [NSString stringWithFormat:@"ePlayer:///Folder/%@", self.uuid];
    NSURL *u = [[NSURL alloc] initWithString:s];
    return u;
}

- (NSArray *)entriesArray
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:self.entries.count];
    for (EPREntry *entry in self.entries) {
        [result addObject:entry];
    }
    return result;
}


- (NSArray *)sortedEntries
{
    NSString *key;
    NSArray *result = [self entriesArray];
    switch (self.sortOrder) {
        case EPSortOrderManual:
            // Already in correct sort order.
            return result;

        case EPSortOrderAlpha:
            return [result sortedArrayUsingComparator:^(EPREntry *obj1, EPREntry *obj2) {
                return [obj1.name localizedCaseInsensitiveCompare:obj2.name];
            }];

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
    // Date sorting.
    return [result sortedArrayUsingComparator:^(EPREntry *obj1, EPREntry *obj2) {
        // Descending order.
        // TODO: Consider performance here.  Perhaps use a pointer to
        // the accessor.
        // performSelector has an annoying warning about a leak.
        //IMP imp = [obj1 methodForSelector:selector];
        //void (*func)(id, SEL) = (void *)imp;
        //func(obj1, selector);

        NSDate *obj1D = [obj1 valueForKey:key];
        NSDate *obj2D = [obj2 valueForKey:key];
        if (!obj1D) {
            if (!obj2D) {
                return NSOrderedSame;
            } else {
                return NSOrderedDescending;
            }
        } else if (!obj2D) {
            return NSOrderedAscending;
        }
        return [obj2D compare:obj1D];
    }];
}

- (NSString *)sectionTitleDate:(NSDate *)date forIndex:(BOOL)forIndex
                         title:(NSString *)title indexTitle:(NSString *)indexTitle
{
    if ([date compare:[NSDate distantPast]] == NSOrderedSame) {
        if (forIndex) {
            return indexTitle;
        } else {
            return title;
        }
    } else {
        return yearFromDate(date);
    }
}

- (NSString *)sectionTitleForEntry:(EPREntry *)entry forIndex:(BOOL)forIndex
{
    switch (self.sortOrder) {
        case EPSortOrderAlpha:
            // Return first character of name.
            if (entry.name.length) {
                return [entry.name substringToIndex:1];
            } else {
                return @"";
            }

        case EPSortOrderAddDate:
            // The word "Unknown" is just too wide for the index.
            return [self sectionTitleDate:entry.addDate forIndex:forIndex
                                    title:@"Unknown" indexTitle:@"??"];

        case EPSortOrderPlayDate:
            return [self sectionTitleDate:entry.playDate forIndex:forIndex
                                    title:@"Never" indexTitle:@"Never"];

        case EPSortOrderReleaseDate:
            return [self sectionTitleDate:entry.releaseDate forIndex:forIndex
                                    title:@"Unknown" indexTitle:@"??"];

        default:
            [NSException raise:@"UnknownSortOrder" format:@"Unknown sort order %i.", self.sortOrder];
    }
    return nil; // Silence warning.
}

// REALM TODO: Use indexedProperties to index this to return quickly.
- (EPRFolder *)folderWithUUID:(NSUUID *)uuid
{
    for (EPREntry *entry in self.entries) {
        if ([entry.class isSubclassOfClass:[EPRFolder class]]) {
            EPRFolder *folder = (EPRFolder *)entry;
            if ([folder.uuid isEqual:uuid]) {
                return folder;
            } else {
                EPRFolder *f = [folder folderWithUUID:uuid];
                if (f) {
                    return f;
                }
            }
        }
    }
    return nil;
}

// REALM TODO: Use indexedProperties.
- (EPRSong *)songWithPersistentID:(long long)persistentID
{
    for (EPREntry *entry in self.entries) {
        if ([entry.class isSubclassOfClass:[EPRSong class]]) {
            EPRSong *song = (EPRSong *)entry;
            if (song.persistentID == persistentID) {
                return song;
            }
        } else {
            EPRFolder *folder = (EPRFolder *)entry;
            EPRSong *s = [folder songWithPersistentID:persistentID];
            if (s) {
                return s;
            }
        }
    }
    return nil;
}

- (void)checkForOrphan
{
    // Create a copy of the entries list so we can delete while iterating
    // over it.
    NSArray *entries = [self entriesArray];
    NSLog(@"ORPHAN: Clearing folder %@", self.name);
    for (EPREntry *subentry in entries) {
        // Remove first so that parents.count can be checked while recursing.
        [self removeEntriesObject:subentry];
        [subentry checkForOrphan];
    }
    if (self.parents.count == 0) {
        NSLog(@"ORPHAN: Permanently removing folder %@", self.name);
    }
}

- (void)removeIfEmpty:(RLMRealm *)realm
{
    if (self.entries.count == 0 && self.parents.count) {
        NSArray *parentsCopy = self.parents;
        [realm deleteObject:self];
        for (EPRFolder *parent in parentsCopy) {
            [parent removeIfEmpty:realm];
        }
    }
}

// REALM TODO: Use indexedProperties.
- (EPRFolder *)folderWithName:(NSString *)name
{
    for (EPREntry *entry in self.entries) {
        if ([entry.name isEqualToString:name] && [entry.class isSubclassOfClass:EPRFolder.class]) {
            return (EPRFolder *)entry;
        }
    }
    return nil;
}

- (NSUInteger)songCount
{
    NSUInteger count=0;
    for (EPREntry *entry in self.entries) {
        count += [entry songCount];
    }
    return count;
}

/*****************************************************************************/
#pragma mark - Entries mutators.
/*****************************************************************************/
- (void)insertObject:(EPREntry *)value inEntriesAtIndex:(NSUInteger)idx
{
    [self.entries insertObject:value atIndex:idx];
    [self incrementDuration:value.duration];
}

- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx
{
    EPREntry *oldEntry = self.entries[idx];
    [self.entries removeObjectAtIndex:idx];
    [self incrementDuration:-oldEntry.duration];
}

- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(EPREntry *)value
{
    EPREntry *oldObject = [self.entries objectAtIndex:idx];
    [self.entries replaceObjectAtIndex:idx withObject:value];
    [self incrementDuration:value.duration-oldObject.duration];
}

- (void)addEntriesObject:(EPREntry *)value
{
    [self.entries addObject:value];
    [self incrementDuration:value.duration];
}

- (void)removeEntriesObject:(EPREntry *)value
{
    while (1) {
        NSUInteger index = [self.entries indexOfObject:value];
        if (index == NSNotFound) {
            break;
        }
        [self.entries removeObjectAtIndex:index];
        [self incrementDuration:-value.duration];
    }
}

- (void)addEntries:(NSArray *)values
{
    [self.entries addObjects:values];
    for (EPREntry *entry in values) {
        [self incrementDuration:entry.duration];
    }
}

- (void)removeEntries:(NSArray *)values
{
    for (EPREntry *entry in values) {
        [self removeEntriesObject:entry];
    }
}

- (void)removeAllEntries
{
    [self.entries removeAllObjects];
    [self incrementDuration:-self.duration];
}


@end
