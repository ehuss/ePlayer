//
//  EPSong.m
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import "EPSong.h"
#import "EPMediaItemWrapper.h"
#import "EPRoot.h"

@implementation EPSong

/*****************************************************************************/
#pragma mark - Realm
/*****************************************************************************/

// Specify default values for properties
//+ (NSDictionary *)defaultPropertyValues
//{
//    return @{};
//}

// Specify properties to ignore (Realm won't persist these)
+ (NSArray *)ignoredProperties
{
    return @[@"mediaItem", @"mediaWrapper"];
}

+ (NSDictionary *)linkingObjectsProperties
{
    return @{
             @"songParents": [RLMPropertyDescriptor descriptorWithClass:EPFolder.class propertyName:@"songs"]
             };
}

- (RLMLinkingObjects *)parents
{
    return self.songParents;
}

/*****************************************************************************/
#pragma mark - Class methods
/*****************************************************************************/

+ (EPSong *)songWithName:(NSString *)name persistentID:(NSNumber *)PID
{
    EPSong *song = [[EPSong alloc] init];
    song.name = name;
    song.persistentID = PID;
    return song;
}

/*****************************************************************************/
#pragma mark - Accessors
/*****************************************************************************/

- (NSURL *)url
{
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"ePlayer:///Song/%@", self.uuid]];
}

- (MPMediaItem *)mediaItem
{
    if (_mediaItem == nil) {
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        MPMediaPropertyPredicate *pred = [MPMediaPropertyPredicate
                                          predicateWithValue:self.persistentID
                                          forProperty:MPMediaItemPropertyPersistentID];
        [query addFilterPredicate:pred];
        NSArray *result = query.items;
        if (result.count) {
            _mediaItem = result[0];
        } else {
            NSLog(@"Failed to fetch MPMediaItem for %@ %@.", self.persistentID, self.name);
        }
    }
    return _mediaItem;
}

- (EPMediaItemWrapper *)mediaWrapper
{
    if (_mediaWrapper == nil) {
        _mediaWrapper = [EPMediaItemWrapper wrapperFromItem:self.mediaItem];
    }
    return _mediaWrapper;
}

- (NSTimeInterval)duration
{
    if (_duration == 0) {
        NSNumber *d = [self.mediaItem valueForProperty:MPMediaItemPropertyPlaybackDuration];
        _duration = [d doubleValue];
    }
    return _duration;
}

/*****************************************************************************/
#pragma mark - Misc
/*****************************************************************************/
- (void)checkForOrphan:(EPRoot *)root
{
    if (self.parents.count == 0) {
        NSLog(@"ORPHAN: Putting song %@ into orphaned.", self.name);
        // Put this song into the orphan folder.
        [root.orphans addSong:self];
    }
}

- (NSUInteger)songCount
{
    return 1;
}

@end
