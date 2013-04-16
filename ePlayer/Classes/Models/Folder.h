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

@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSSet *entries;
@property (nonatomic, strong) NSArray *sortedEntries;
@end

@interface Folder (CoreDataGeneratedAccessors)

- (void)addEntriesObject:(Entry *)value;
- (void)removeEntriesObject:(Entry *)value;
- (void)addEntries:(NSSet *)values;
- (void)removeEntries:(NSSet *)values;

@end
