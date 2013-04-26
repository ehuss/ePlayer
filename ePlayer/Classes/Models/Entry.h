//
//  Entry.h
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Folder;

@interface Entry : NSManagedObject

- (void)propagatePlayCount:(NSUInteger)count;
- (void)propagatePlayDate:(NSDate *)date;
- (void)propagateAddDate:(NSDate *)date;
- (void)propagateReleaseDate:(NSDate *)date;

@property (nonatomic, retain) NSDate * addDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * playDate;
@property (nonatomic, retain) NSDate * releaseDate;
@property (nonatomic, retain) NSNumber * playCount;
@property (nonatomic, retain) NSSet *parents;
@end

@interface Entry (CoreDataGeneratedAccessors)

- (void)addParentsObject:(Folder *)value;
- (void)removeParentsObject:(Folder *)value;
- (void)addParents:(NSSet *)values;
- (void)removeParents:(NSSet *)values;

@end
