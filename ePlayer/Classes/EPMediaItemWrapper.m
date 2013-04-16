//
//  EPMediaItemWrapper.m
//  ePlayer
//
//  Created by Eric Huss on 4/15/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPMediaItemWrapper.h"

@implementation EPMediaItemWrapper

+ (EPMediaItemWrapper *)wrapperFromItem:(MPMediaItem *)mediaItem
{
    EPMediaItemWrapper *wrapper = [[EPMediaItemWrapper alloc] init];
    wrapper.item = mediaItem;
    return wrapper;
}

- (NSString *)albumPersistentID
{
    return [self.item valueForProperty:MPMediaItemPropertyAlbumPersistentID];
}

- (NSString *)title
{
    return [self.item valueForProperty:MPMediaItemPropertyTitle];
}

- (NSString *)albumTitle
{
    return [self.item valueForProperty:MPMediaItemPropertyAlbumTitle];
}

- (NSString *)artist
{
    return [self.item valueForProperty:MPMediaItemPropertyArtist];
}

- (NSString *)albumArtist
{
    NSString *name = [self.item valueForProperty:MPMediaItemPropertyAlbumArtist];
    if (name == nil) {
        return [self.item valueForProperty:MPMediaItemPropertyArtist];
    } else {
        return name;
    }
}

@end
