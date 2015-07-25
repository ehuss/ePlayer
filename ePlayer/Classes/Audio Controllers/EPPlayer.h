//
//  EPPlayer.h
//  ePlayer
//
//  Created by Eric Huss on 7/21/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EPEntry.h"
#import "EPRoot.h"

extern NSString *kEPPlayNotification;
extern NSString *kEPStopNotification;
extern NSString *kEPQueueFinishedNotification;
// This is primarily used to update the display when tracks change.
extern NSString *kEPPlayerUpdateNotification;

@interface EPPlayer : NSObject

@property (nonatomic) BOOL isPlaying;
@property (nonatomic, readonly) EPRoot *root;
@property (nonatomic) NSTimeInterval currentPlaybackTime;
// The duration of the currently playing track.
@property (nonatomic, readonly) NSTimeInterval currentDuration;

- (void)setPlayingIsStopped;
- (void)dbAppendEntry:(EPEntry *)entry;

/****************************************************************************/
/* Subclass Methods                                                         */
/****************************************************************************/
- (void)play;
- (void)pause;
// Stop does not reset the current play position.
- (void)stop;
// This will stop play, switch to this index.  Play remains stopped.
- (void)switchToQueueIndex:(NSInteger)index;
// Stop playing, clear the queue, add the following entry to the queue.
- (void)replaceQueue:(EPEntry *)entry;
// Appends the given entry to the queue.
- (void)appendEntry:(EPEntry *)entry;
// Begins fast fowarding.
// Seeking continues until endSeeking is called.
- (void)beginSeekingForward;
// Begins fast rewinding.
// Seeking continues until endSeeking is called.
- (void)beginSeekingBackward;
- (void)endSeeking;
// Called when switching backends.
- (void)shutdown;

@end
