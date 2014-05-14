//
//  Folder.m
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#import "EPFolder.h"

@implementation EPFolder

/*****************************************************************************/
#pragma mark - Class methods
/*****************************************************************************/
+ (EPFolder *)folderWithName:(NSString *)name
                   sortOrder:(EPSortOrder)sortOrder
                 releaseDate:(NSDate *)releaseDate
                     addDate:(NSDate *)addDate
                    playDate:(NSDate *)playDate
{
    EPFolder *folder = [[EPFolder alloc] init];
    folder.name = name;
    folder.sortOrder = sortOrder;
    folder.releaseDate = releaseDate;
    folder.addDate = addDate;
    folder.playDate = playDate;
    folder.entries = [[NSMutableArray alloc] init];
    folder.parents = [[NSMutableSet alloc] init];
    folder.uuid = [NSUUID UUID];
    return folder;
}

/*****************************************************************************/
#pragma mark - NSCoding
/*****************************************************************************/
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _sortOrder = [aDecoder decodeIntForKey:@"sortOrder"];
        _entries = [aDecoder decodeObjectForKey:@"entries"];
        _uuid = [aDecoder decodeObjectForKey:@"uuid"];
        _duration = [aDecoder decodeDoubleForKey:@"duration"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInt:_sortOrder forKey:@"sortOrder"];
    [aCoder encodeObject:_entries forKey:@"entries"];
    [aCoder encodeObject:_uuid forKey:@"uuid"];
    [aCoder encodeDouble:_duration forKey:@"duration"];
}

/*****************************************************************************/
#pragma mark - NSCopying
/*****************************************************************************/

- (id)copyWithZone:(NSZone *)zone
{
    EPFolder *folder = [super copyWithZone:zone];
    if (folder) {
        folder->_sortOrder = _sortOrder;
        folder->_entries = [NSMutableArray arrayWithArray:_entries];
        folder->_uuid = [NSUUID UUID];
        for (EPEntry *entry in _entries) {
            [entry.parents addObject:folder];
        }
    }
    return folder;
}

/*****************************************************************************/
#pragma mark - Misc
/*****************************************************************************/

- (NSTimeInterval)duration
{
    return _duration;
}

- (void)incrementDuration:(NSTimeInterval)duration
{
    _duration += duration;
    for (EPFolder *parent in self.parents) {
        [parent incrementDuration:duration];
    }
}

- (NSURL *)url
{
    NSString *s = [NSString stringWithFormat:@"ePlayer:///Folder/%@", self.uuid.UUIDString];
    NSURL *u = [[NSURL alloc] initWithString:s];
    return u;
}


- (NSArray *)sortedEntries
{
    SEL s;
    switch (self.sortOrder) {
        case EPSortOrderManual:
            // Already in correct sort order.
            return self.entries;
            
        case EPSortOrderAlpha:
            return [self.entries sortedArrayUsingComparator:^(EPEntry *obj1, EPEntry *obj2) {
                return [obj1.name localizedCaseInsensitiveCompare:obj2.name];
            }];
            
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
    // Date sorting.
    return [self.entries sortedArrayUsingComparator:^(EPEntry *obj1, EPEntry *obj2) {
        // Descending order.
        NSDate *obj1D = [obj1 performSelector:s];
        NSDate *obj2D = [obj2 performSelector:s];
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

- (NSString *)sectionTitleForEntry:(EPEntry *)entry forIndex:(BOOL)forIndex
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

- (EPFolder *)folderWithUUID:(NSUUID *)uuid
{
    for (EPEntry *entry in self.entries) {
        if ([entry.class isSubclassOfClass:[EPFolder class]]) {
            EPFolder *folder = (EPFolder *)entry;
            if ([folder.uuid isEqual:uuid]) {
                return folder;
            } else {
                EPFolder *f = [folder folderWithUUID:uuid];
                if (f) {
                    return f;
                }
            }
        }
    }
    return nil;
}

- (EPSong *)songWithPersistentID:(NSNumber *)persistentID
{
    for (EPEntry *entry in self.entries) {
        if ([entry.class isSubclassOfClass:[EPSong class]]) {
            EPSong *song = (EPSong *)entry;
            if ([song.persistentID isEqual:persistentID]) {
                return song;
            }
        } else {
            EPFolder *folder = (EPFolder *)entry;
            EPSong *s = [folder songWithPersistentID:persistentID];
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
    NSArray *entries = [NSArray arrayWithArray:self.entries];
    NSLog(@"ORPHAN: Clearing folder %@", self.name);
    for (EPEntry *subentry in entries) {
        // Remove first so that parents.count can be checked while recursing.
        [self removeEntriesObject:subentry];
        [subentry checkForOrphan];
    }
    if (self.parents.count == 0) {
        NSLog(@"ORPHAN: Permanently removing folder %@", self.name);
    }
}

- (void)removeIfEmpty
{
    if (self.entries.count == 0 && self.parents.count) {
        NSSet *parentsCopy = [NSSet setWithSet:self.parents];
        for (EPFolder *parent in parentsCopy) {
            [parent removeEntriesObject:self];
        }
        for (EPFolder *parent in parentsCopy) {
            [parent removeIfEmpty];
        }
    }
}

- (EPFolder *)folderWithName:(NSString *)name
{
    for (EPEntry *entry in self.entries) {
        if ([entry.name isEqualToString:name] && [entry.class isSubclassOfClass:EPFolder.class]) {
            return (EPFolder *)entry;
        }
    }
    return nil;
}

/*****************************************************************************/
#pragma mark - Entries mutators.
/*****************************************************************************/
- (void)insertObject:(EPEntry *)value inEntriesAtIndex:(NSUInteger)idx
{
    [self.entries insertObject:value atIndex:idx];
    [value.parents addObject:self];
    [self incrementDuration:value.duration];
}

- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx
{
    EPEntry *oldEntry = self.entries[idx];
    [self.entries removeObjectAtIndex:idx];
    [self incrementDuration:-oldEntry.duration];
}

- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(EPEntry *)value
{
    EPEntry *oldObject = [self.entries objectAtIndex:idx];
    [self.entries replaceObjectAtIndex:idx withObject:value];
    [value.parents addObject:self];
    if (![self.entries containsObject:oldObject]) {
        // Last occurance of this object.        
        [oldObject.parents removeObject:self];
    }
    [self incrementDuration:value.duration-oldObject.duration];
}

- (void)addEntriesObject:(EPEntry *)value
{
    [self.entries addObject:value];
    [value.parents addObject:self];
    [self incrementDuration:value.duration];
}

- (void)removeEntriesObject:(EPEntry *)value
{
    while (1) {
        NSUInteger index = [self.entries indexOfObject:value];
        if (index == NSNotFound) {
            break;
        }
        [self.entries removeObjectAtIndex:index];
        [self incrementDuration:-value.duration];
    }
    [value.parents removeObject:self];
}

- (void)addEntries:(NSArray *)values
{
    [self.entries addObjectsFromArray:values];
    for (EPEntry *entry in values) {
        [entry.parents addObject:self];
        [self incrementDuration:entry.duration];
    }
}

- (void)removeEntries:(NSArray *)values
{
    for (EPEntry *entry in values) {
        [self removeEntriesObject:entry];
        [entry.parents removeObject:self];
    }
}

- (void)removeAllEntries
{
    for (EPEntry *entry in self.entries) {
        [entry.parents removeObject:self];
    }
    [self.entries removeAllObjects];
    [self incrementDuration:-self.duration];
}


@end
