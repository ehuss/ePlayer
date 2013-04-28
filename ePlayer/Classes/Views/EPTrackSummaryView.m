//
//  EPTrackSummaryView.m
//  ePlayer
//
//  Created by Eric Huss on 4/27/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPTrackSummaryView.h"
#import "EPMediaItemWrapper.h"

@implementation EPTrackSummaryView

- (void)awakeFromNib
{
    [[NSBundle mainBundle] loadNibNamed:@"TrackSummary" owner:self options:nil];
    [self addSubview:self.contentView];
}

- (void)loadSong:(Song *)song
{
    if (song) {
        self.artistName.text = song.mediaWrapper.artist;
        self.albumName.text = song.mediaWrapper.albumTitle;
        self.trackName.text = song.mediaWrapper.title;
        if (song.mediaWrapper.releaseYear == 0) {
            self.releasedDate.text = nil;
        } else {
            self.releasedDate.text = [NSString stringWithFormat:@"Released %i", song.mediaWrapper.releaseYear];
        }
        MPMediaItemArtwork *art = song.mediaWrapper.artwork;
        UIImage *image = nil;
        if (art) {
            image = [art imageWithSize:self.albumArt.frame.size];
        }
        if (image) {
            self.albumArt.image = image;
        } else {
            self.albumArt.image = [UIImage imageNamed:@"missing-art"];
        }
    } else {
        self.artistName.text = nil;
        self.albumName.text = nil;
        self.trackName.text = nil;
        self.releasedDate.text = nil;
        self.albumArt.image = [UIImage imageNamed:@"missing-art"];
    }
}

@end
