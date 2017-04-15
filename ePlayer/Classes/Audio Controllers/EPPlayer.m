//
//  EPPlayer.m
//  ePlayer
//
//  Created by Eric Huss on 7/21/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import "EPPlayer.h"

NSString *kEPPlayNotification = @"EPPlayNotification";
NSString *kEPStopNotification = @"EPStopNotification";
NSString *kEPQueueFinishedNotification = @"EPQueueFinishedNotification";
NSString *kEPPlayerUpdateNotification = @"EPNextSongStarted";

@implementation EPPlayer

/****************************************************************************/
#pragma mark - Misc
/****************************************************************************/

- (void)setPlayingIsStopped
{
    if (self.isPlaying) {
        self.isPlaying = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kEPStopNotification object:nil];
}

- (void)dbAppendEntry:(EPEntry *)entry
{
    if ([entry.class isSubclassOfClass:[EPFolder class]]) {
        EPFolder *folder = (EPFolder *)entry;
        for (EPEntry *child in folder.sortedEntries) {
            [self dbAppendEntry:child];
        }
        [folder propagatePlayCount:1];
        [folder propagatePlayDate:[NSDate date]];
    } else {
        // is Song type.
        [self.root.queue addSong:(EPSong *)entry];
    }
}

/****************************************************************************/
#pragma mark - Accessors
/****************************************************************************/
- (EPRoot *)root
{
    return [EPRoot sharedRoot];
}

- (NSTimeInterval)currentDuration
{
    if (self.root.currentQueueIndex < self.root.queue.songs.count) {
        EPSong *song = (EPSong *)self.root.queue.songs[self.root.currentQueueIndex];
        return song.duration;
    }
    return 0;
}

/****************************************************************************/
#pragma mark - Subclass Methods
/****************************************************************************/
- (NSTimeInterval)currentPlaybackTime
{
    return 0;
}
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
}
- (void)play
{
}
- (void)pause
{
}
- (void)stop
{
}
- (void)switchToQueueIndex:(NSInteger)index
{
}
- (void)replaceQueue:(EPEntry *)entry
{
    [self stop];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    // Clear the queue.
    NSArray *oldEnts = [self.root.queue.songs realmToArray];
    [self.root.queue removeAllEntries];
    for (EPEntry *ent in oldEnts) {
        [ent checkForOrphan:self.root];
    }
    self.root.currentQueueIndex = 0;
    [self dbAppendEntry:entry];
    [realm commitWriteTransaction];
}
- (void)appendEntry:(EPEntry *)entry
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [self dbAppendEntry:entry];
    [realm commitWriteTransaction];
}
- (void)beginSeekingForward
{
}
- (void)beginSeekingBackward
{
}
- (void)endSeeking
{
}
- (void)shutdown
{
}

@end
