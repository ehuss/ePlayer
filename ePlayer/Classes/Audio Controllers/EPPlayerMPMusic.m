//
//  EPPlayerMPMusic.m
//  ePlayer
//
//  Created by Eric Huss on 7/23/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "EPPlayerMPMusic.h"

@implementation EPPlayerMPMusic

- (id)init
{
    self = [super init];
    if (self) {
        // This has been renamed to systemMusicPlayer in iOS 8.
        self.mpPlayer = [MPMusicPlayerController iPodMusicPlayer];
        [self registerNotifications];
    }
    return self;
}

- (BOOL)isPlaying
{
    // playbackState is completely bugged.
    // NOTE: It looks like it has been fixed if your deployment target is
    // iOS 8+.  Unfortunately I still want to support 7. :(
    // MPMusicPlayerControllerPlaybackStateDidChangeNotification is called
    // multiple times.  It ends up in the "paused" state when it is really
    // playing.  This is noted by multiple people on the forums and
    // stackoverflow.
//    UInt32 audioIsPlaying;
//    UInt32 size = sizeof(audioIsPlaying);
//    AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &audioIsPlaying);
//    NSLog(@"other audio Is Playing=%u", audioIsPlaying);
//    NSLog(@"playbackState=%i playbackRate=%f", (int)self.mpPlayer.playbackState, self.mpPlayer.currentPlaybackRate);
    // 1 = playing
    // 2 = paused

    // currentPlaybackRate is not 100% reliable.
    // One bug: after finishing the queue, the playback rate stays at 1.
    if (self.mpPlayer.playbackState == MPMusicPlaybackStateStopped) {
        return NO;
    }
    return self.mpPlayer.currentPlaybackRate > 0;

    return self.mpPlayer.playbackState == MPMusicPlaybackStatePlaying ||
           self.mpPlayer.playbackState == MPMusicPlaybackStateSeekingBackward ||
           self.mpPlayer.playbackState == MPMusicPlaybackStateSeekingForward;
}

- (void)setIsPlaying:(BOOL)isPlaying
{
    abort();
    [NSException raise:@"Internal Error" format:@"do not set isPlaying"];
}

/****************************************************************************/
#pragma mark - Notifications
/****************************************************************************/
- (void)registerNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(playerUpdated:)
                               name:
     MPMusicPlayerControllerPlaybackStateDidChangeNotification
                             object:self.mpPlayer];
    [notificationCenter addObserver:self
                           selector:@selector(nowPlayingUpdate:)
                               name:
     MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                             object:self.mpPlayer];
    [self.mpPlayer beginGeneratingPlaybackNotifications];
}

- (void)nowPlayingUpdate:(NSNotification *)notification
{
//    NSLog(@"now playing update");

    if (self.mpPlayer.indexOfNowPlayingItem == NSNotFound) {
        // Queue is empty (typically happens when the last track has finished).
        self.root.currentQueueIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:kEPQueueFinishedNotification object:nil];
    } else {
        self.root.currentQueueIndex = self.mpPlayer.indexOfNowPlayingItem;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kEPPlayerUpdateNotification object:nil];
}

- (void)playerUpdated:(NSNotification *)notification
{
    // See notes about playbackState being bugged.
//    NSLog(@"player udpated state=%i", (int)self.mpPlayer.playbackState);

    [[NSNotificationCenter defaultCenter] postNotificationName:kEPPlayerUpdateNotification object:nil];
}

/****************************************************************************/
#pragma mark - EPPlayer Subclass Methods
/****************************************************************************/

- (NSTimeInterval)currentPlaybackTime
{
    return self.mpPlayer.currentPlaybackTime;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
    self.mpPlayer.currentPlaybackTime = currentPlaybackTime;
}

- (void)play
{
    if (!self.isPlaying && self.root.queue.entries.count) {
        [self.mpPlayer play];
//        self.isPlaying = YES;
    }
}

- (void)pause
{
    if (self.isPlaying) {
        [self.mpPlayer pause];
    }
    [self setPlayingIsStopped];
}

- (void)stop
{
    if (self.isPlaying) {
        [self.mpPlayer stop];
    }
}

- (void)switchToQueueIndex:(NSInteger)index
{
    EPSong *song = self.root.queue.entries[index];
    self.root.currentQueueIndex = index;
    // TODO: How does this handle when playing?
    // XXX: Consider using the skipToNextItem API instead, since that is all
    //      this is really used for.
    self.mpPlayer.nowPlayingItem = song.mediaItem;
}

- (void)replaceQueue:(EPEntry *)entry;
{
    [super replaceQueue:entry];
    [self dbAppendEntry:entry];
    NSArray *items = [self.root.queue.entries mapWithBlock:^MPMediaItem *(EPSong *song) {
        return song.mediaItem;
    }];
    MPMediaItemCollection *collection = [MPMediaItemCollection collectionWithItems:items];
    [self.mpPlayer setQueueWithItemCollection:collection];
}

- (void)appendEntry:(EPEntry *)entry
{
    [self dbAppendEntry:entry];
    self.root.dirty = YES;
    // TODO: What happens if playing?
    // TODO: Share code with replaceQueue.
    NSArray *items = [self.root.queue.entries mapWithBlock:^MPMediaItem *(EPSong *song) {
        return song.mediaItem;
    }];
    MPMediaItemCollection *collection = [MPMediaItemCollection collectionWithItems:items];
    [self.mpPlayer setQueueWithItemCollection:collection];
    // TODO: Set nowPlayingItem with value from before?
}

- (void)beginSeekingForward
{
    [self.mpPlayer beginSeekingForward];
}

- (void)beginSeekingBackward
{
    [self.mpPlayer beginSeekingBackward];
}

- (void)endSeeking
{
    [self.mpPlayer endSeeking];
}

- (void)shutdown
{
    [self stop];
}

@end
