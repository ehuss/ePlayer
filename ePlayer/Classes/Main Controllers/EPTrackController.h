//
//  EPTrackController.h
//  ePlayer
//
//  Created by Eric Huss on 4/27/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPTrackSummaryView.h"
#import "EPLyricView.h"
#import "EPCommon.h"
#import "EPSong.h"

/*
 Controller for the view displayed when tapping a song in the browser.
 
 It displays the name, album art, play data, lyrics, etc.
*/

@interface EPTrackController : UIViewController
@property (weak, nonatomic) IBOutlet EPTrackSummaryView *trackSummary;
@property (weak, nonatomic) IBOutlet EPLyricView *lyricView;

- (void)loadSong:(EPSong *)song;

@end
