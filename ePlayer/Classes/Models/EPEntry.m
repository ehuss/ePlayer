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
        _playCount = [aDecoder decodeIntForKey:@"playCount"];
        _parents = [aDecoder decodeObjectForKey:@"parents"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.addDate forKey:@"addDate"];
    [aCoder encodeObject:self.playDate forKey:@"playDate"];
    [aCoder encodeObject:self.releaseDate forKey:@"releaseDate"];
    [aCoder encodeInt:self.playCount forKey:@"playCount"];
    [aCoder encodeObject:self.parents forKey:@"parents"];
}

/*****************************************************************************/
#pragma mark - NSCopying
/*****************************************************************************/

- (id)copyWithZone:(NSZone *)zone
{
    EPEntry *entry = [[self.class allocWithZone:zone] init];
    if (entry) {
        entry->_name = [NSString stringWithFormat:@"%@ Copy", self.name];
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


/*****************************************************************************/
#pragma mark - Propagate Methods
/*****************************************************************************/
- (void)propagatePlayCount:(int)count
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
