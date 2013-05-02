//
//  Song.m
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPSong.h"
#import "EPMediaItemWrapper.h"
#import "EPRoot.h"

@implementation EPSong

/*****************************************************************************/
#pragma mark - Class methods
/*****************************************************************************/

+ (EPSong *)songWithName:(NSString *)name persistentID:(NSNumber *)PID
{
    EPSong *song = [[EPSong alloc] init];
    song.name = name;
    song.persistentID = PID;
    song.parents = [[NSMutableSet alloc] init];
    return song;
}

/*****************************************************************************/
#pragma mark - NSCoding
/*****************************************************************************/

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.persistentID = [aDecoder decodeObjectForKey:@"persistentID"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.persistentID forKey:@"persistentID"];
}

/*****************************************************************************/
#pragma mark - Accessors
/*****************************************************************************/

- (NSURL *)url
{
    return [[NSURL alloc] initWithString:[NSString stringWithFormat:@"ePlayer:///Song/%@", self.persistentID]];
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
- (void)checkForOrphan
{
    if (self.parents.count == 0) {
        NSLog(@"ORPHAN: Putting song %@ into orphaned.", self.name);
        // Put this song into the orphan folder.
        EPRoot *root = [EPRoot sharedRoot];
        EPFolder *orphanFolder = [root getOrMakeOraphans];
        [orphanFolder addEntriesObject:self];
    }
}


@end
