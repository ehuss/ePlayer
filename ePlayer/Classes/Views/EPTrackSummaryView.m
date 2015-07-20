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
    [super awakeFromNib];
    NSArray *ts = [[NSBundle mainBundle] loadNibNamed:@"TrackSummary2" owner:self options:nil];
    UIView *v = ts[0];
    [self addSubview:v];
    // I don't know why, but this is very important.  Otherwise, the autolayout
    // just does random shit.
    v.frame = self.bounds;
}

- (void)loadSong:(EPSong *)song
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
