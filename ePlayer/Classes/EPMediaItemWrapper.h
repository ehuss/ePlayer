//
//  EPMediaItemWrapper.h
//  ePlayer
//
//  Created by Eric Huss on 4/15/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface EPMediaItemWrapper : NSObject

+ (EPMediaItemWrapper *)wrapperFromItem:(MPMediaItem *)mediaItem;

@property (strong, nonatomic) MPMediaItem *item;

@property (readonly, nonatomic) NSNumber *albumPersistentID;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *albumTitle;
@property (readonly, nonatomic) NSString *artist;
@property (readonly, nonatomic) NSString *albumArtist;

@end
