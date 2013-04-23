//
//  Folder.h
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Entry.h"

@class Entry;

@interface Folder : Entry

- (NSString *)sectionTitleForEntry:(Entry *)entry;

- (NSArray *)sortedEntries;

- (Folder *)clone;

@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSOrderedSet *entries;

@end

// Working around a bug in Core Data's auto-generated code.
// This was raising an exception (set argument is not an NSSet).
// See http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors
// Now using https://github.com/CFKevinRef/KCOrderedAccessorFix
@interface Folder (KCCoredDataGeneratedAccessors)
- (void)insertObject:(Entry *)value inEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx;
- (void)insertEntries:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeEntriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(Entry *)value;
- (void)replaceEntriesAtIndexes:(NSIndexSet *)indexes withEntries:(NSArray *)values;
- (void)addEntriesObject:(Entry *)value;
- (void)removeEntriesObject:(Entry *)value;
- (void)addEntries:(NSOrderedSet *)values;
- (void)removeEntries:(NSOrderedSet *)values;
@end

//@interface Folder (CoreDataGeneratedAccessors)
//
//- (void)insertObject:(Entry *)value inEntriesAtIndex:(NSUInteger)idx;
//- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx;
//- (void)insertEntries:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
//- (void)removeEntriesAtIndexes:(NSIndexSet *)indexes;
//- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(Entry *)value;
//- (void)replaceEntriesAtIndexes:(NSIndexSet *)indexes withEntries:(NSArray *)values;
//- (void)addEntriesObject:(Entry *)value;
//- (void)removeEntriesObject:(Entry *)value;
//- (void)addEntries:(NSOrderedSet *)values;
//- (void)removeEntries:(NSOrderedSet *)values;
//
//@end
