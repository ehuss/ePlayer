//
//  Song.h
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EPEntry.h"

@class EPMediaItemWrapper;

@interface EPSong : EPEntry <NSCoding>
{
    MPMediaItem *_mediaItem;
    EPMediaItemWrapper *_mediaWrapper;
}

// Unsigned 64-bit.
@property (retain, nonatomic) NSNumber * persistentID;
@property (readonly, nonatomic) MPMediaItem *mediaItem;
@property (readonly, nonatomic) EPMediaItemWrapper *mediaWrapper;
@property (readonly, nonatomic) NSTimeInterval duration;

+ (EPSong *)songWithName:(NSString *)name persistentID:(NSNumber *)PID;

@end
