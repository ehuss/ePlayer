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
        self.sortOrder = [aDecoder decodeIntForKey:@"sortOrder"];
        self.entries = [aDecoder decodeObjectForKey:@"entries"];
        self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInt:self.sortOrder forKey:@"sortOrder"];
    [aCoder encodeObject:self.entries forKey:@"entries"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
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
        return [[obj2 performSelector:s] compare:[obj1 performSelector:s]];
    }];
}


- (NSString *)sectionTitleForEntry:(EPEntry *)entry;
{
    switch (self.sortOrder) {
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

/*****************************************************************************/
#pragma mark - Entries mutators.
/*****************************************************************************/
- (void)insertObject:(EPEntry *)value inEntriesAtIndex:(NSUInteger)idx
{
    [self.entries insertObject:value atIndex:idx];
    [value.parents addObject:self];
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
}

- (void)addEntriesObject:(EPEntry *)value
{
    [self.entries addObject:value];
    [value.parents addObject:self];
}

- (void)removeEntriesObject:(EPEntry *)value
{
    [self.entries removeObject:value];
    [value.parents removeObject:self];
}

- (void)addEntries:(NSArray *)values
{
    [self.entries addObjectsFromArray:values];
    for (EPEntry *entry in values) {
        [entry.parents addObject:self];
    }
}

- (void)removeEntries:(NSArray *)values
{
    for (EPEntry *entry in values) {
        [self.entries removeObject:entry];
        [entry.parents removeObject:self];
    }
}

- (void)removeAllEntries
{
    for (EPEntry *entry in self.entries) {
        [entry.parents removeObject:self];
    }
    [self.entries removeAllObjects];
}


@end
