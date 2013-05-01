//
//  EPTrackController.m
//  ePlayer
//
//  Created by Eric Huss on 4/27/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPTrackController.h"

@interface EPTrackController ()

@end

@implementation EPTrackController

- (void)loadSong:(EPSong *)song
{
    // Force view to load (otherwise subviews would be nil).
    [self view];
    [self.trackSummary loadSong:song];
    [self.lyricView updateWithSong:song];
}

@end
