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

+ (EPPlayerController *)sharedPlayer;
- (void)loadCurrentQueue;

- (void)play;
- (void)pause;
- (void)stop;
- (void)clearQueue;
// Array of MPMediaItem objects.
- (void)addQueueItems:(NSArray *)items;
- (IBAction)tappedPrev:(id)sender;
- (IBAction)tappedPlay:(id)sender;
- (IBAction)tappedNext:(id)sender;
- (IBAction)tappedSave:(id)sender;

- (IBAction)scrubberDidUpdate:(id)sender;
- (IBAction)scrubberTouchDown:(id)sender;
- (IBAction)scrubberTouchUp:(id)sender;

//@property (weak, nonatomic) IBOutlet UIView *currentPlayingView;
//@property (weak, nonatomic) IBOutlet UIImageView *albumCoverView;
//@property (weak, nonatomic) IBOutlet UILabel *artistNameLabel;
//@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
//@property (weak, nonatomic) IBOutlet UILabel *timeLeftLabel;
//@property (weak, nonatomic) IBOutlet EPScrubberView *scrubber;
//@property (strong, nonatomic) UIButton *prevButton;
//@property (strong, nonatomic) UIButton *nextButton;
//@property (strong, nonatomic) UIButton *playButton;
////@property (strong, nonatomic) UIButton *pauseButton;
//@property (strong, nonatomic) UIButton *saveButton;
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
@property (readonly, nonatomic) BOOL isDisplayed;
@end
