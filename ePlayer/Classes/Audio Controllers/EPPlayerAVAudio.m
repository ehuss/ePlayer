//
//  EPPlayerAVAudio.m
//  ePlayer
//
//  Created by Eric Huss on 7/21/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import "EPPlayerAVAudio.h"
#import "EPMediaItemWrapper.h"
#import "NSMutableDictionary+EP.h"

@implementation EPPlayerAVAudio

/****************************************************************************/
#pragma mark - EPPlayer Subclass Methods
/****************************************************************************/

- (NSTimeInterval)currentPlaybackTime
{
    if (self.currentPlayer) {
        return self.currentPlayer.currentTime;
    } else {
        return 0;
    }
}
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
    if (self.currentPlayer) {
        self.currentPlayer.currentTime = currentPlaybackTime;
        [self nextPlayerPrepare];
    }
}

- (void)play
{
    if (!self.isPlaying && self.root.queue.songs.count) {
        if (self.currentPlayer == nil) {
            [self setCurrentPlayer];
        }
        [self.currentPlayer play];
        self.isPlaying = YES;
        [self nextPlayerPrepare];
        [self updateNowPlayingInfoCenter];
    }
}

- (void)pause
{
    if (self.isPlaying) {
        [self.currentPlayer pause];
        if (self.nextPlayer) {
            [self.nextPlayer pause];
        }
        [self setPlayingIsStopped];
    }
}

- (void)stop
{
    if (self.isPlaying) {
        [self.currentPlayer stop];
        if (self.nextPlayer) {
            [self.nextPlayer stop];
        }
        [self setPlayingIsStopped];
    }
}

- (void)switchToQueueIndex:(NSInteger)index
{
    [self stop];
    [self.root transUpdateIndex:index];
    [self setCurrentPlayer];
}

- (void)replaceQueue:(EPEntry *)entry
{
    [super replaceQueue:entry];
    self.currentPlayer = nil;
    self.nextPlayer = nil;
}

- (void)beginSeekingForward
{
    if (self.isPlaying) {
        self.seekTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                          target:self
                                                        selector:@selector(seekForwardTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];
        if (self.nextPlayer) {
            [self.nextPlayer stop];
            self.nextPlayer = nil;
        }
    }
}

- (void)beginSeekingBackward
{
    if (self.isPlaying) {
        self.seekTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                          target:self
                                                        selector:@selector(seekBackwardsTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];
        if (self.nextPlayer) {
            [self.nextPlayer stop];
            self.nextPlayer = nil;
        }
    }
}

- (void)endSeeking
{
    [self nextPlayerPrepare];
    [self.seekTimer invalidate];
    self.seekTimer = nil;
}

static NSTimeInterval seekAmount = 2.0;

- (void)seekForwardTimerFired:(NSTimer *)timer
{
    if (self.currentPlayer) {
        self.currentPlayer.currentTime += seekAmount;
    }
}

- (void)seekBackwardsTimerFired:(NSTimer *)timer
{
    if (self.currentPlayer) {
        self.currentPlayer.currentTime -= seekAmount;
    }
}

- (void)shutdown
{
    [self stop];
    self.currentPlayer = nil;
    self.nextPlayer = nil;
}


/****************************************************************************/
#pragma mark - AVAudioPlayer Support
/****************************************************************************/

- (AVAudioPlayer *)playerForIndex:(NSInteger)index
{
    EPSong *song = (EPSong *)self.root.queue.songs[index];
    NSURL *url = [song.mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    NSError *error;
    AVAudioPlayer *player;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    player.delegate = self;
    if (error) {
        NSLog(@"Failed to create AVAudioPlayer url %@: %@", url, error);
        return nil;
    }
    return player;
}

- (void)setCurrentPlayer
{
    assert(!self.isPlaying);
    self.currentPlayer = [self playerForIndex:self.root.currentQueueIndex];
    if (self.root.currentQueueIndex < self.root.queue.songs.count-1) {
        self.nextPlayer = [self playerForIndex:self.root.currentQueueIndex+1];
    } else {
        self.nextPlayer = nil;
    }
}

- (void)nextPlayerPrepare
{
    if (self.nextPlayer && self.isPlaying) {
        [self.nextPlayer stop];
        NSTimeInterval now = self.currentPlayer.deviceCurrentTime;
        NSTimeInterval diff = self.currentPlayer.duration - self.currentPlayer.currentTime;
        [self.nextPlayer playAtTime:now+diff];
    }
}

- (void)updateNowPlayingInfoCenter
{
    if (self.isPlaying) {
        EPSong *song = (EPSong *)self.root.queue.songs[self.root.currentQueueIndex];
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
        [info ep_setOptObject:song.mediaWrapper.albumTitle forKey:MPMediaItemPropertyAlbumTitle];
        [info ep_setOptObject:song.mediaWrapper.artist forKey:MPMediaItemPropertyArtist];
        [info ep_setOptObject:song.mediaWrapper.artwork forKey:MPMediaItemPropertyArtwork];
        [info ep_setOptObject:song.persistentID forKey:MPMediaItemPropertyPersistentID];
        [info ep_setOptObject:[song.mediaItem valueForProperty:MPMediaItemPropertyPlaybackDuration] forKey:MPMediaItemPropertyPlaybackDuration];
        [info ep_setOptObject:song.name forKey:MPMediaItemPropertyTitle];
        [info ep_setOptObject:@(self.currentPlayer.currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [info ep_setOptObject:@(self.root.currentQueueIndex) forKey:MPNowPlayingInfoPropertyPlaybackQueueIndex];
        [info ep_setOptObject:@(self.root.queue.songs.count) forKey:MPNowPlayingInfoPropertyPlaybackQueueCount];
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
    } else {
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    }

}

/****************************************************************************/
#pragma mark - AVAudioPlayer Delegate
/****************************************************************************/

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
//    NSLog(@"%@ Did finish: %i", player, (int)flag);
    if (flag) {
        EPSong *finishedSong = (EPSong *)self.root.queue.songs[self.root.currentQueueIndex];
        if (self.root.currentQueueIndex < self.root.queue.songs.count-1) {
            // Prepare for the next track to play.
            [self.root transUpdateIndex:self.root.currentQueueIndex+1];
            if (self.nextPlayer) {
                // Assume nextPlayer will pick up.
                self.currentPlayer = self.nextPlayer;
                if (self.root.currentQueueIndex < self.root.queue.songs.count-1) {
                    // Prepare the next track.
                    self.nextPlayer = [self playerForIndex:self.root.currentQueueIndex+1];
                    [self nextPlayerPrepare];
                } else {
                    // No next track.
                    self.nextPlayer = nil;
                }
            } else {
                // This can happen if entries are added to the queue while playing
                // the last entry.  Could fix the queue commands, but that's a
                // rare case.
                self.isPlaying = NO;  // setCurrentPlayer requires this.
                [self setCurrentPlayer];
                [self play];
            }
        } else {
            // At the end of the queue.
            self.currentPlayer = nil;
            self.nextPlayer = nil;  // Probably redundant.
            [self.root transUpdateIndex:0];
            [self setPlayingIsStopped];
            [[NSNotificationCenter defaultCenter] postNotificationName:kEPQueueFinishedNotification object:nil];
        }
        [[RLMRealm defaultRealm] transactionWithBlock:^ {
            finishedSong.playCount += 1;
            finishedSong.playDate = [NSDate date];
        }];
    } else {
        // Decode failure.
        if (self.nextPlayer) {
            [self.nextPlayer stop];
            self.nextPlayer = nil;
        }
        [self setPlayingIsStopped];
    }
    [self updateNowPlayingInfoCenter];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kEPPlayerUpdateNotification object:nil];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode error: %@", error);
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    NSLog(@"Begin interruption.");
    // Automatically paused.
    if (self.isPlaying) {
        self.interruptedWhilePlaying = YES;
        [self setPlayingIsStopped];
    }
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags
{
    NSLog(@"End interruption.");
    // Unpause.
    if (self.interruptedWhilePlaying) {
        self.interruptedWhilePlaying = NO;
        [self play];
    }
}


@end
