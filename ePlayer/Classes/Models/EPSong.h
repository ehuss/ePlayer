//
//  EPSong.h
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

#import <Realm/Realm.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EPEntry.h"

// Forward declaration.
@class EPMediaItemWrapper;

@interface EPSong : EPEntry
{
    // These are not persisted in Realm, accessed from the
    // iOS media database as-needed.
    MPMediaItem *_mediaItem;
    EPMediaItemWrapper *_mediaWrapper;
    NSTimeInterval _duration;
}

@property NSNumber<RLMInt> *persistentID;
@property (readonly) RLMLinkingObjects *songParents;

@property (readonly, nonatomic) MPMediaItem *mediaItem;
@property (readonly, nonatomic) EPMediaItemWrapper *mediaWrapper;

+ (EPSong *)songWithName:(NSString *)name persistentID:(NSNumber *)PID;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<EPSong>
RLM_ARRAY_TYPE(EPSong)
