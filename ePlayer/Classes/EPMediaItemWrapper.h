//
//  EPMediaItemWrapper.h
//  ePlayer
//
//  Created by Eric Huss on 4/15/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EPCommon.h"

@interface EPMediaItemWrapper : NSObject
{
    NSDate *_releaseDate;
}

+ (EPMediaItemWrapper *)wrapperFromItem:(MPMediaItem *)mediaItem;
+ (NSArray *)sortedArrayOfWrappers:(NSArray *)wrappers
                           inOrder:(EPSortOrder)order
                          alphaKey:(NSString *)alphaKey;

- (NSString *)sectionTitleForSortOrder:(EPSortOrder)sortOrder
                              alphaKey:(NSString *)alphaKey;

@property (strong, nonatomic) MPMediaItem *item;

@property (readonly, nonatomic) NSNumber *persistentID;
@property (readonly, nonatomic) NSNumber *albumPersistentID;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *albumTitle;
@property (readonly, nonatomic) NSString *artist;
@property (readonly, nonatomic) NSString *albumArtist;
@property (readonly, nonatomic) NSDate *lastPlayedDate;
@property (readonly, nonatomic) NSDate *releaseDate;
@property (readonly, nonatomic) int releaseYear;
@property (readonly, nonatomic) NSNumber *playCount;
@property (readonly, nonatomic) NSString *composer;
@property (readonly, nonatomic) NSString *lyrics;
@property (readonly, nonatomic) NSURL *url;
@property (readonly, nonatomic) MPMediaItemArtwork *artwork;

@end
