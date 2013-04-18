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

static NSString *const kItemsKey = @"entries";

- (void)removeEntries:(NSOrderedSet *)values
{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet
                                          orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
    }
}


//
//static NSString *const kItemsKey = @"subitems";
//
//- (void)insertObject:(FRPlaylistItem *)value inSubitemsAtIndex:(NSUInteger)idx {
//    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
//    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    [tmpOrderedSet insertObject:value atIndex:idx];
//    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
//}
//
//- (void)removeObjectFromSubitemsAtIndex:(NSUInteger)idx {
//    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
//    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    [tmpOrderedSet removeObjectAtIndex:idx];
//    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
//}
//
//- (void)insertSubitems:(NSArray *)values atIndexes:(NSIndexSet *)indexes {
//    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    [tmpOrderedSet insertObjects:values atIndexes:indexes];
//    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
//}
//
//- (void)removeSubitemsAtIndexes:(NSIndexSet *)indexes {
//    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    [tmpOrderedSet removeObjectsAtIndexes:indexes];
//    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
//}
//
//- (void)replaceObjectInSubitemsAtIndex:(NSUInteger)idx withObject:(FRPlaylistItem *)value {
//    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
//    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kItemsKey];
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    [tmpOrderedSet replaceObjectAtIndex:idx withObject:value];
//    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kItemsKey];
//}
//
//- (void)replaceSubitemsAtIndexes:(NSIndexSet *)indexes withSubitems:(NSArray *)values {
//    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kItemsKey];
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    [tmpOrderedSet replaceObjectsAtIndexes:indexes withObjects:values];
//    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexes forKey:kItemsKey];
//}
//
//- (void)addSubitemsObject:(FRPlaylistItem *)value {
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    NSUInteger idx = [tmpOrderedSet count];
//    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
//    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
//    [tmpOrderedSet addObject:value];
//    [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
//}
//
//- (void)removeSubitemsObject:(FRPlaylistItem *)value {
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    NSUInteger idx = [tmpOrderedSet indexOfObject:value];
//    if (idx != NSNotFound) {
//        NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
//        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
//        [tmpOrderedSet removeObject:value];
//        [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:kItemsKey];
//    }
//}
//
//- (void)addSubitems:(NSOrderedSet *)values {
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:kItemsKey]];
//    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
//    NSUInteger valuesCount = [values count];
//    NSUInteger objectsCount = [tmpOrderedSet count];
//    for (NSUInteger i = 0; i < valuesCount; ++i) {
//        [indexes addIndex:(objectsCount + i)];
//    }
//    if (valuesCount > 0) {
//        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
//        [tmpOrderedSet addObjectsFromArray:[values array]];
//        [self setPrimitiveValue:tmpOrderedSet forKey:kItemsKey];
//        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:kItemsKey];
//    }
//}
//



@end
