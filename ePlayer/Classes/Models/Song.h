//
//  Song.h
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Entry.h"

@class EPMediaItemWrapper;

@interface Song : Entry
{
    MPMediaItem *_mediaItem;
    EPMediaItemWrapper *_mediaWrapper;
}

@property (nonatomic, retain) NSNumber * persistentID;
// Unsigned version, since core data doesn't support unsigned.
@property (readonly, nonatomic) NSNumber *UPID;
@property (readonly, nonatomic) MPMediaItem *mediaItem;
@property (readonly, nonatomic) EPMediaItemWrapper *mediaWrapper;
@property (readonly, nonatomic) NSTimeInterval duration;

@end
