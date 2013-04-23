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

@interface EPPlayerController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (void)loadCurrentQueue;

- (void)play;
- (void)pause;
- (void)stop;
- (void)clearQueue;
// Array of MPMediaItems.
- (void)changeQueueItems:(NSArray *)items;

// Stop, clear queue, and play these items.
- (void)playItems:(NSArray *)items;
// Array of MPMediaItem objects.
- (void)addQueueItems:(NSArray *)items;
- (IBAction)tappedPrev:(id)sender;
- (IBAction)tappedPlay:(id)sender;
- (IBAction)tappedNext:(id)sender;
- (IBAction)tappedSave:(id)sender;

- (IBAction)scrubberDidUpdate:(id)sender;
- (IBAction)scrubberTouchDown:(id)sender;
- (IBAction)scrubberTouchUp:(id)sender;

- (void)playEntry:(Entry *)entry;

- (void)updateVolumeImage;

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

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong) Folder *queueFolder;

@property (strong, nonatomic) MPMusicPlayerController *player;
@property (strong, nonatomic) MPMediaItemCollection *queueItems;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) BOOL scrubberUpdateDisabled;
@property (assign, nonatomic) NSTimeInterval lastScrubberUpdate;
@property (assign, nonatomic) int lastScrubberPlayTime;
// Determines if we are going to be displayed.
// I can't check self.view.window or self.tabBarController.selectedViewController == self
// since I want to do things in viewWillAppear, and those haven't updated, yet.
@property (assign, nonatomic) BOOL isDisplayed;
@end
