//
//  EPREntry.m
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import "EPREntry.h"
#import "EPRFolder.h"

@implementation EPREntry

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues
{
    NSDate *now = [NSDate date];
    return @{@"uuid": @"",
             @"name": @"",
             @"addDate": now,
             @"playDate": now,
             @"releaseDate": now,
             @"playCount": @0};
}

+ (NSString *)primaryKey {
    return @"uuid";
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}


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

+ (NSDictionary *)linkingObjectsProperties {
    return @{
             @"owners": [RLMPropertyDescriptor descriptorWithClass:EPREntry.class propertyName:@"parents"],
    };
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
    for (EPRFolder *parent in self.parents) {
        NSMutableArray *chainCopy = [NSMutableArray arrayWithArray:chain];
        [parent addPaths:chainCopy intoResults:results];
    }
    if (self.parents.count == 0) {
        [results addObject:chain];
    }
}

- (NSUInteger)songCount
{
    return 0;
}

/*****************************************************************************/
#pragma mark - Propagate Methods
/*****************************************************************************/
// TODO: UPDATE FOR REALM.
- (void)propagatePlayCount:(NSInteger)count
{
//    self.playCount += count;
//    for (EPEntry *folder in self.parents) {
//        [folder propagatePlayCount:count];
//    }
}

- (void)propagatePlayDate:(NSDate *)date;
{
//    NSDate *newDate = [date laterDate:self.playDate];
//    self.playDate = newDate;
//    for (EPEntry *folder in self.parents) {
//        [folder propagatePlayDate:newDate];
//    }
}

- (void)propagateAddDate:(NSDate *)date;
{
//    NSDate *newDate = [date laterDate:self.addDate];
//    self.addDate = newDate;
//    for (EPEntry *folder in self.parents) {
//        [folder propagateAddDate:newDate];
//    }
}

- (void)propagateReleaseDate:(NSDate *)date;
{
//    NSDate *newDate = [date laterDate:self.releaseDate];
//    self.releaseDate = newDate;
//    for (EPEntry *folder in self.parents) {
//        [folder propagateReleaseDate:newDate];
//    }
}


@end
