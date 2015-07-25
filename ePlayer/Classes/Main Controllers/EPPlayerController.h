//
//  PlayerController.h
//  ePlayer
//
//  Created by Eric Huss on 4/12/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>
#import "EPScrubberView.h"
#import "EPCommon.h"
#import "EPTrackSummaryView.h"
#import "EPLyricView.h"
#import "EPFolder.h"
#import "EPPlayer.h"


@class EPMainTabController;

@interface EPPlayerController : UIViewController <UITableViewDelegate,
                                                  UITableViewDataSource>

// Called after object context is set.
- (void)mainInit;
- (void)handleRemoteControlEvent:(UIEvent *)event;

// Player commands.
- (void)play;
- (void)pause;

// This will stop playback, replace the queue with the given entry, and start playback.
- (void)playEntry:(EPEntry *)entry;
- (void)appendEntry:(EPEntry *)entry;

- (BOOL)shouldAppend;

// Called when the backend setting is changed.
- (void)changeAudioBackend;

// Actions
- (IBAction)tappedPrev:(id)sender;
- (IBAction)tappedPlay:(id)sender;
- (IBAction)tappedNext:(id)sender;
- (IBAction)heldPrev:(id)sender;
- (IBAction)heldNext:(id)sender;

- (IBAction)scrubberDidUpdate:(id)sender;
- (IBAction)scrubberTouchDown:(id)sender;
- (IBAction)scrubberTouchUp:(id)sender;

// Interface Builder Views
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet EPTrackSummaryView *trackSummary;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet EPScrubberView *scrubber;
@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;
@property (weak, nonatomic) IBOutlet EPLyricView *lyricView;
@property (weak, nonatomic) IBOutlet UIView *centralView;

// Player
@property (nonatomic) EPPlayer *player;
@property (readonly, nonatomic) float volume;
// This is used for volume/libray stuff.
@property (strong, nonatomic) MPMusicPlayerController *mpPlayer;
@property (assign, nonatomic) NSTimeInterval lastFastSeekTime;

// Scrubber/Display update support.
@property (strong, nonatomic) NSTimer *timer;
// This is used to disable automatic scrubber updates while the user is modifying it.
@property (assign, nonatomic) BOOL scrubberManualUpdating;
// This value is the play time that the scrubber last set.  This is used so that
// if another scrubber update comes in, we can prevent updates that are less
// than a second.
@property (assign, nonatomic) NSTimeInterval lastScrubberUpdate;
@property (assign, nonatomic) int lastScrubberPlayTime;
// Determines if we are going to be displayed.
// I can't check self.view.window or self.tabBarController.selectedViewController == self
// since I want to do things in viewWillAppear, and those haven't updated, yet.
@property (assign, nonatomic) BOOL isDisplayed;
@property (readonly, nonatomic) EPMainTabController *mainTabController;

@end
