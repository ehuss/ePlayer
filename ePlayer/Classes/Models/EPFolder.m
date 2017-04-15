//
//  EPFolder.m
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import "EPFolder.h"
#import "EPRoot.h"

@implementation EPFolder

/*****************************************************************************/
#pragma mark - Realm
/*****************************************************************************/

// Specify default values for properties
//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

+ (NSDictionary *)linkingObjectsProperties
{
    return @{
             @"folderParents": [RLMPropertyDescriptor descriptorWithClass:EPFolder.class propertyName:@"folders"]
             };
}

- (RLMLinkingObjects *)parents
{
    return self.folderParents;
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

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
    return folder;
}

/*****************************************************************************/
#pragma mark - Misc
/*****************************************************************************/

- (void)incrementDuration:(NSTimeInterval)duration
{
    self.duration += duration;
    for (EPFolder *parent in self.parents) {
        [parent incrementDuration:duration];
    }
}

- (NSURL *)url
{
    NSString *s = [NSString stringWithFormat:@"ePlayer:///Folder/%@", self.uuid];
    NSURL *u = [[NSURL alloc] initWithString:s];
    return u;
}

- (NSArray *)sortedEntries
{
    NSString *key;
    NSArray *folders = [self.folders realmToArray];
    NSArray *songs = [self.songs realmToArray];
    NSArray *result = [folders arrayByAddingObjectsFromArray:songs];
    switch (self.sortOrder) {
        case EPSortOrderManual:
            // Already in correct sort order.
            return result;

        case EPSortOrderAlpha:
            return [result sortedArrayUsingComparator:^(EPEntry *obj1, EPEntry *obj2) {
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
    return [result sortedArrayUsingComparator:^(EPEntry *obj1, EPEntry *obj2) {
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

- (void)checkForOrphan:(EPRoot *)root
{
    if (self.parents.count == 0) {
        NSLog(@"ORPHAN %@", self.name);
        [root.orphans addFolder:self];
    }
}

- (void)removeIfEmpty:(RLMRealm *)realm
{
    if (self.folders.count == 0 && self.songs.count == 0 && self.parents.count) {
        NSArray *parentsCopy = [self.parents realmToArray];
        [realm deleteObject:self];
        // Recrusively delete parents if they are now empty, too.
        for (EPFolder *parent in parentsCopy) {
            [parent removeIfEmpty:realm];
        }
    }
}

- (EPFolder *)folderWithName:(NSString *)name
{
    for (EPFolder *folder in self.folders) {
        if ([folder.name isEqualToString:name]) {
            return folder;
        }
    }
    return nil;
}

- (NSUInteger)songCount
{
    NSUInteger count = self.songs.count;
    for (EPFolder *folder in self.folders) {
        count += [folder songCount];
    }
    return count;
}

/*****************************************************************************/
#pragma mark - Entries mutators.
/*****************************************************************************/
- (void)moveFolderAtIndex:(NSUInteger)sourceIndex
                  toIndex:(NSUInteger)destinationIndex
{
    [self.folders moveObjectAtIndex:sourceIndex toIndex:destinationIndex];
}

- (void)moveSongAtIndex:(NSUInteger)sourceIndex
                toIndex:(NSUInteger)destinationIndex
{
    [self.songs moveObjectAtIndex:sourceIndex toIndex:destinationIndex];
}

- (void)insertFolder:(EPFolder *)folder atIndex:(NSUInteger)idx
{
    [self.folders insertObject:folder atIndex:idx];
    [self incrementDuration:folder.duration];
}

- (void)replaceFolderAtIndex:(NSUInteger)index
                  withFolder:(EPFolder *)folder
{
    EPFolder *oldFolder = self.folders[index];
    [self.folders replaceObjectAtIndex:index withObject:folder];
    [self incrementDuration:folder.duration-oldFolder.duration];
}

- (void)addFolder:(EPFolder *)folder
{
    [self.folders addObject:folder];
    [self incrementDuration:folder.duration];
}

- (void)addSong:(EPSong *)song
{
    [self.songs addObject:song];
    [self incrementDuration:song.duration];
}

- (void)addEntry:(EPEntry *)entry
{
    if ([entry.class isSubclassOfClass:[EPFolder class]]) {
        [self addFolder:(EPFolder *)entry];
    } else {
        [self addSong:(EPSong *)entry];
    }
}

- (void)addSongs:(id <NSFastEnumeration>)songs
{
    for (EPSong *song in songs) {
        [self addSong:song];
    }
}

- (void)addFolders:(id <NSFastEnumeration>)folders
{
    for (EPFolder *folder in folders) {
        [self addFolder:folder];
    }
}

- (void)removeSong:(EPSong *)song
{
    [self removeGeneric:song inArray:self.songs];
}

- (void)removeFolder:(EPFolder *)folder
{
    [self removeGeneric:folder inArray:self.folders];
}

- (void)removeGeneric:(EPEntry *)entry inArray:(RLMArray *)entries
{
    while (1) {
        NSUInteger index = [entries indexOfObject:entry];
        if (index == NSNotFound) {
            return;
        }
        [entries removeObjectAtIndex:index];
        [self incrementDuration:-entry.duration];
    }
}

- (void)removeEntry:(EPEntry *)entry
{
    if ([entry.class isSubclassOfClass:[EPFolder class]]) {
        [self removeFolder:(EPFolder *)entry];
    } else {
        [self removeSong:(EPSong *)entry];
    }
}

- (void)removeAllEntries
{
    [self.folders removeAllObjects];
    [self.songs removeAllObjects];
    [self incrementDuration:-self.duration];
}

- (void)removeEntries:(id <NSFastEnumeration>)entries
{
    for (EPEntry *entry in entries) {
        [self removeEntry:entry];
    }
}


@end
