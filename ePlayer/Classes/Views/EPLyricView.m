//
//  EPLyricView.m
//  ePlayer
//
//  Created by Eric Huss on 4/27/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPLyricView.h"
#import "EPMediaItemWrapper.h"

@implementation EPLyricView

- (void)updateWithSong:(Song *)song
{
    NSMutableString *text = [[NSMutableString alloc] init];
    // Artist
    NSString *artist = song.mediaWrapper.artist;
    NSString *albumArtist = song.mediaWrapper.albumArtist;
    if (artist != nil && albumArtist != nil && ![artist isEqualToString:albumArtist]) {
        [text appendString:[NSString stringWithFormat:@"Artist: %@\n", artist]];
    }
    // Composer
    if (song.mediaWrapper.composer) {
        [text appendString:[NSString stringWithFormat:@"Composer: %@\n", song.mediaWrapper.composer]];
    }
    // Last Play Date
    NSString *playDate;
    if (song.playDate == nil) {
        playDate = @"Never";
    } else {
        playDate = [NSDateFormatter localizedStringFromDate:song.playDate
                                                  dateStyle:NSDateFormatterMediumStyle
                                                  timeStyle:NSDateFormatterNoStyle];
    }
    [text appendString:[NSString stringWithFormat:@"Last Play Date: %@\n", playDate]];
    // Play Count
    [text appendString:[NSString stringWithFormat:@"Play Count: %@\n", song.playCount]];
    // Added Date
    NSString *addDate = [NSDateFormatter localizedStringFromDate:song.addDate
                                                       dateStyle:NSDateFormatterMediumStyle
                                                       timeStyle:NSDateFormatterNoStyle];
    [text appendString:[NSString stringWithFormat:@"Added To Library: %@\n", addDate]];

    [text appendString:@"\n"];
    if (song.mediaWrapper.lyrics) {
        [text appendString:song.mediaWrapper.lyrics];
    }
    self.text = text;
}

@end
