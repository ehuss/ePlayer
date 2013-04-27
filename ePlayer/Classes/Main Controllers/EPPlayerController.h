//
//  PlayerController.h
//  ePlayer
//
//  Created by Eric Huss on 4/12/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>
#import "EPScrubberView.h"
#import "EPCommon.h"

@class EPMainTabController;

@interface EPPlayerController : UIViewController <UITableViewDelegate,
                                                  UITableViewDataSource,
                                                  AVAudioPlayerDelegate>
{
    Folder *_queueFolder;
}

// Called after object context is set.
- (void)mainInit;

// Player commands.
- (void)play;
- (void)pause;
- (void)clearQueue;
// This will stop play, switch to this index.  Play remains stopped.
- (void)switchToQueueIndex:(int)index;

- (void)playEntry:(Entry *)entry;
- (void)appendEntry:(Entry *)entry;

// Actions
- (IBAction)tappedPrev:(id)sender;
- (IBAction)tappedPlay:(id)sender;
- (IBAction)tappedNext:(id)sender;

- (IBAction)scrubberDidUpdate:(id)sender;
- (IBAction)scrubberTouchDown:(id)sender;
- (IBAction)scrubberTouchUp:(id)sender;

// Interface Builder Views
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIImageView *artImageView;
@property (weak, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *releasedDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet EPScrubberView *scrubber;
@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;

// Core Data
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) Folder *queueFolder;
@property (assign, nonatomic) int currentQueueIndex;

// Player
@property (strong, nonatomic) AVAudioPlayer *currentPlayer;
@property (strong, nonatomic) AVAudioPlayer *nextPlayer;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL interruptedWhilePlaying;
@property (readonly, nonatomic) float volume;
// This is used for volume/libray stuff.
@property (strong, nonatomic) MPMusicPlayerController *mpPlayer;

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
