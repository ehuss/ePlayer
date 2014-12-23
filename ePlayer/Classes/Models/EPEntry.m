//
//  Entry.m
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPEntry.h"
#import "EPFolder.h"
#import "EPRoot.h"

@implementation EPEntry

/*****************************************************************************/
#pragma mark - NSCoding
/*****************************************************************************/

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _addDate = [aDecoder decodeObjectForKey:@"addDate"];
        _playDate = [aDecoder decodeObjectForKey:@"playDate"];
        _releaseDate = [aDecoder decodeObjectForKey:@"releaseDate"];
        _playCount = [aDecoder decodeIntegerForKey:@"playCount"];
        _parents = [aDecoder decodeObjectForKey:@"parents"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_addDate forKey:@"addDate"];
    [aCoder encodeObject:_playDate forKey:@"playDate"];
    [aCoder encodeObject:_releaseDate forKey:@"releaseDate"];
    [aCoder encodeInteger:_playCount forKey:@"playCount"];
    [aCoder encodeObject:_parents forKey:@"parents"];
}

/*****************************************************************************/
#pragma mark - NSCopying
/*****************************************************************************/

- (id)copyWithZone:(NSZone *)zone
{
    EPEntry *entry = [[self.class allocWithZone:zone] init];
    if (entry) {
        entry->_name = self.name;
        entry->_addDate = [NSDate date];
        entry->_playDate = _playDate;
        entry->_releaseDate = _releaseDate;
        entry->_playCount = _playCount;
        entry->_parents = [[NSMutableSet alloc] init];
    }
    return entry;
}

/*****************************************************************************/
#pragma mark - Accessors
/*****************************************************************************/

- (NSTimeInterval)duration
{
    // Subclasses implement.
    return 0;
}

- (NSURL *)url
{
    // Subclasses implement.
    return nil;
}

/*****************************************************************************/
#pragma mark - Misc
/*****************************************************************************/

- (void)checkForOrphan
{
    // Subclasses implement.
    return;
}

- (NSArray *)pathNames
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    NSMutableArray *selfChain = [[NSMutableArray alloc] init];
    [self addPaths:selfChain intoResults:paths];
    for (NSMutableArray *chain in paths) {
        NSString *path = [chain componentsJoinedByString:@"/"];
        [result addObject:path];
    }
    return result;
}

- (void)addPaths:(NSMutableArray *)chain intoResults:(NSMutableArray *)results
{
    [chain insertObject:self.name atIndex:0];
    for (EPFolder *parent in self.parents) {
        NSMutableArray *chainCopy = [NSMutableArray arrayWithArray:chain];
        [parent addPaths:chainCopy intoResults:results];
    }
    if (self.parents.count == 0) {
        [results addObject:chain];
    }
}


/*****************************************************************************/
#pragma mark - Propagate Methods
/*****************************************************************************/
- (void)propagatePlayCount:(NSInteger)count
{
    self.playCount += count;
    for (EPEntry *folder in self.parents) {
        [folder propagatePlayCount:count];
    }
}

- (void)propagatePlayDate:(NSDate *)date;
{
    NSDate *newDate = [date laterDate:self.playDate];
    self.playDate = newDate;
    for (EPEntry *folder in self.parents) {
        [folder propagatePlayDate:newDate];
    }
}

- (void)propagateAddDate:(NSDate *)date;
{
    NSDate *newDate = [date laterDate:self.addDate];
    self.addDate = newDate;
    for (EPEntry *folder in self.parents) {
        [folder propagateAddDate:newDate];
    }
}

- (void)propagateReleaseDate:(NSDate *)date;
{
    NSDate *newDate = [date laterDate:self.releaseDate];
    self.releaseDate = newDate;
    for (EPEntry *folder in self.parents) {
        [folder propagateReleaseDate:newDate];
    }
}


@end
