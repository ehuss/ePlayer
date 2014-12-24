//
//  PlayerController.m
//  ePlayer
//
//  Created by Eric Huss on 4/12/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "NSNotificationCenter+MainThread.h"
#import "EPPlayerController.h"
#import "EPPlayerCellView.h"
#import "UIImage+EPCrop.h"
#import "NSMutableDictionary+EP.h"
#import "EPMediaItemWrapper.h"
#import "EPMainTabController.h"
#import "EPRoot.h"

//static NSTimeInterval scrubberUpdateTime = 0.300;

NSString *kEPPlayNotification = @"EPPlayNotification";
NSString *kEPStopNotification = @"EPStopNotification";

/****************************************************************************/
#pragma mark - Audio Callback
/****************************************************************************/

void audioRouteChangeListenerCallback (void                      *inUserData,
                                       AudioSessionPropertyID    inPropertyID,
                                       UInt32                    inPropertyValueSize,
                                       const void                *inPropertyValue
                                       )
{
	// ensure that this callback was invoked for a route change
	if (inPropertyID != kAudioSessionProperty_AudioRouteChange) {
        return;
    }
    
	// This callback, being outside the implementation block, needs a reference to the
	//		MainViewController object, which it receives in the inUserData parameter.
	//		You provide this reference when registering this callback (see the call to
	//		AudioSessionAddPropertyListener).
	EPPlayerController *controller = (__bridge EPPlayerController *) inUserData;

    // XXX: interruptedWhilePlaying?
    if (controller.isPlaying) {
		// Determines the reason for the route change, to ensure that it is not
		//		because of a category change.
		CFDictionaryRef	routeChangeDictionary = inPropertyValue;
		
		CFNumberRef routeChangeReasonRef = CFDictionaryGetValue(
                              routeChangeDictionary,
                              CFSTR (kAudioSession_AudioRouteChangeKey_Reason));
        
		SInt32 routeChangeReason;
 		CFNumberGetValue(routeChangeReasonRef,
                         kCFNumberSInt32Type,
                         &routeChangeReason);
		
		// "Old device unavailable" indicates that a headset was unplugged, or that the
		//	device was removed from a dock connector that supports audio output. This is
		//	the recommended test for when to pause audio.
		if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            [controller pause];
			NSLog(@"Output device removed, so application audio was paused.");
            
//			UIAlertView *routeChangeAlertView =
//            [[UIAlertView alloc]	initWithTitle: NSLocalizedString (@"Playback Paused", @"Title for audio hardware route-changed alert view")
//                                       message: NSLocalizedString (@"Audio output was changed", @"Explanation for route-changed alert view")
//                                      delegate: controller
//                             cancelButtonTitle: NSLocalizedString (@"StopPlaybackAfterRouteChange", @"Stop button title")
//                             otherButtonTitles: NSLocalizedString (@"ResumePlaybackAfterRouteChange", @"Play button title"), nil];
//			[routeChangeAlertView show];
			// release takes place in alertView:clickedButtonAtIndex: method
            
		} else {
			NSLog (@"A route change occurred that does not require pausing of application audio.");
		}
	}
}

/****************************************************************************/
#pragma mark - Implementation
/****************************************************************************/

@implementation EPPlayerController

- (void)mainInit
{
    self.mpPlayer = [MPMusicPlayerController applicationMusicPlayer];
    [self registerNotifications];
    [self updateVolumeImage];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    // I think for the other tabs, the NavigationBar is forcing this
    // (probably because of the settings in the app plist).  Not sure if there
    // is a better, global way to set this
    // (set UIViewControllerBasedStatusBarAppearance to NO?).  Well, regardless
    // I need to redo the coloring anyways, this will fix the problem for now
    // (was getting black text on a black background).
    return UIStatusBarStyleBlackOpaque;
}

- (EPMainTabController *)mainTabController
{
    return (EPMainTabController *)self.tabBarController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Register the class for creating cells.
    UINib *entryNib = [UINib nibWithNibName:@"PlayerCell" bundle:nil];
    [self.tableView registerNib:entryNib forCellReuseIdentifier:@"PlayerCell"];
    // The gesture recognizers for the notification center seems to prevent
    // recognizing touches near the top of the screen.  Instead of catching
    // touch events on the info button, this has been changed so the entire
    // track summary can be tapped.
    UIGestureRecognizer *r = [[UITapGestureRecognizer alloc]
                              initWithTarget:self action:@selector(tappedInfo:)];
    [self.trackSummary addGestureRecognizer:r];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isDisplayed = YES;
    [self updateDisplay];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.isDisplayed = NO;
    [self stopTimer];
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    [self.tableView reloadData];
//}
//
//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

/****************************************************************************/
#pragma mark - Accessors
/****************************************************************************/
- (EPRoot *)root
{
    return [EPRoot sharedRoot];
}

/****************************************************************************/
#pragma mark - Table view data source
/****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.root.queue.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlayerCell";
    EPPlayerCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    EPSong *song = self.root.queue.entries[indexPath.row];
    cell.queueNumLabel.text = [NSString stringWithFormat:@"%li.", indexPath.row+1];
    cell.trackNameLabel.text = song.name;
    cell.albumNameLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                song.mediaWrapper.albumTitle,
                                song.mediaWrapper.albumArtist];
    int duration = (int)song.duration;
    cell.trackTimeLabel.text = [NSString stringWithFormat:@"%i:%02i",
                                 duration/60, duration%60];
    if (self.root.currentQueueIndex == indexPath.row) {
        [cell setCurrent:self.isPlaying];
    } else {
        [cell unsetCurrent];
    }
    [cell setEvenOdd:indexPath.row%2];
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath
{
//    MPMediaItem *item = [self.queueItems objectAtIndex:fromIndexPath.row];
//    [self.queueItems removeObjectAtIndex:fromIndexPath.row];
//    [self.queueItems insertObject:item atIndex:toIndexPath.row];
}


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/****************************************************************************/
#pragma mark - Table view delegate
/****************************************************************************/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self switchToQueueIndex:indexPath.row];
    [self play];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

/****************************************************************************/
#pragma mark - Button Actions
/****************************************************************************/
- (void)tappedInfo:(id)sender
{
    if (!self.tableView.hidden) {
        [self.lyricView updateWithSong:self.root.queue.entries[self.root.currentQueueIndex]];
    }
    NSUInteger transitionType = (self.tableView.hidden ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft);
    
    [UIView transitionWithView:self.centralView
                      duration:0.75
                       options:transitionType
                    animations:^{
                        self.tableView.hidden = !self.tableView.hidden;
                        self.lyricView.hidden = !self.lyricView.hidden;
                    }
                    completion:NULL];
    [UIView transitionWithView:self.trackSummary.flipButtonView
                      duration:0.75
                       options:transitionType
                    animations:^{
                        self.trackSummary.infoButton.hidden = !self.trackSummary.infoButton.hidden;
                        self.trackSummary.listButton.hidden = !self.trackSummary.listButton.hidden;
                    }
                    completion:NULL];
}

- (void)tappedPrev:(id)sender
{
    [self prevTrack];
}

- (IBAction)tappedPlay:(id)sender
{
    if (self.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}

- (IBAction)tappedNext:(id)sender
{
    [self nextTrack];
}

- (IBAction)heldPrev:(UILongPressGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self beginSeekingBackward];
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self endSeekingBackward];
            break;
            
        default:
            break;
    }
}

- (IBAction)heldNext:(UILongPressGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self beginSeekingForward];
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self endSeekingForward];
            break;

        default:
            break;
    }
}


- (IBAction)scrubberDidUpdate:(id)sender
{
    // XXX: Track change now-playing while holding scrubber?  Stop/pause/interrupt?
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    // Don't update too frequently.
//    if ((now-self.lastScrubberUpdate) > scrubberUpdateTime) {
    // Compute the playback time for this thumb position.
    NSTimeInterval duration = (int)self.currentPlayer.duration;
    NSTimeInterval newPlaybackTime = duration*self.scrubber.value;
    // Only alter it if the change is >= 1 second.
    if ((int)newPlaybackTime != self.lastScrubberPlayTime) {
        self.lastScrubberPlayTime = (int)newPlaybackTime;
        self.lastScrubberUpdate = now;
        self.currentPlayer.currentTime = duration*self.scrubber.value;
        [self nextPlayerPrepare];
//        NSLog(@"updated to %f", self.currentPlayer.currentTime);
        [self updateTimeLabels];
    }
  //  }
//    NSLog(@"scrubber update %f %f", self.scrubber.scrubbingSpeed,
//          self.scrubber.value);
}

- (IBAction)scrubberTouchDown:(id)sender
{
    self.scrubberManualUpdating = YES;
    // Force the first DidUpdate to update the player.
    self.lastScrubberUpdate = 0;//[NSDate timeIntervalSinceReferenceDate];
    self.lastScrubberPlayTime = self.currentPlayer.currentTime;
}

- (IBAction)scrubberTouchUp:(id)sender
{
    self.scrubberManualUpdating = NO;
}


/****************************************************************************/
#pragma mark - Player Methods
/****************************************************************************/
- (void)setPlayingIsStopped
{
    self.isPlaying = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kEPStopNotification object:nil];
}

- (BOOL)shouldAppend
{
    // Was considering handling the situation where you are in the middle of
    // the queue, and you pause.  Perhaps it should return YES in that case?
    // It would require a "finishedPlaying" bool that is triggered when the
    // queue hits the end.  Alternatively, just check if at the very beginning
    // of the queue (and assume that only happens when the queue finishes,
    // which is not true in the case of appending to an empty queue).
    return self.isPlaying;
}


- (void)play
{
    NSLog(@"Play");
    if (!self.isPlaying && self.root.queue.entries.count) {
        if (self.currentPlayer == nil) {
            [self setCurrentPlayer];
        }
        [self.currentPlayer play];
        [self nextPlayerPrepare];
        self.isPlaying = YES;
        [self updateDisplay];
        [self updateNowPlayingInfoCenter];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEPPlayNotification object:nil];
        
    }
}

- (void)nextPlayerPrepare
{
    if (self.nextPlayer) {
        [self.nextPlayer stop];
        NSTimeInterval now = self.currentPlayer.deviceCurrentTime;
        NSTimeInterval diff = self.currentPlayer.duration - self.currentPlayer.currentTime;
        [self.nextPlayer playAtTime:now+diff];
    }
}

- (AVAudioPlayer *)playerForIndex:(NSInteger)index
{
    EPSong *song = self.root.queue.entries[index];
    NSURL *url = [song.mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    NSError *error;
    AVAudioPlayer *player;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    player.delegate = self;
    if (error) {
        NSLog(@"Failed to create AVAudioPlayer: %@", error);
        return nil;
    }
    return player;    
}

- (void)setCurrentPlayer
{
    assert(!self.isPlaying);
    self.currentPlayer = [self playerForIndex:self.root.currentQueueIndex];
    if (self.root.currentQueueIndex < self.root.queue.entries.count-1) {
        self.nextPlayer = [self playerForIndex:self.root.currentQueueIndex+1];
    } else {
        self.nextPlayer = nil;
    }
}

- (void)pause
{
    if (self.isPlaying) {
        [self.currentPlayer pause];
        if (self.nextPlayer) {
            [self.nextPlayer pause];
        }
        [self setPlayingIsStopped];
        [self updateDisplay];
    }
}

// Stop does not reset the current play position.
- (void)stop
{
    if (self.isPlaying) {
        [self.currentPlayer stop];
        if (self.nextPlayer) {
            [self.nextPlayer stop];
        }
        [self setPlayingIsStopped];
    }
}

- (void)nextTrack
{
    if (self.root.queue.entries.count) {
        if (self.root.currentQueueIndex == self.root.queue.entries.count-1) {
            [self stop];
            [self switchToQueueIndex:0];
        } else {
            // Switch to next song.
            BOOL wasPlaying = self.isPlaying;
            [self switchToQueueIndex:self.root.currentQueueIndex+1];
            if (wasPlaying) {
                [self play];
            }
        }
    }    
}

- (void)prevTrack
{
    if (self.root.queue.entries.count) {
        if (self.root.currentQueueIndex == 0) {
            // Set playback position to 0.
            if (self.currentPlayer) {
                self.currentPlayer.currentTime = 0;
                [self nextPlayerPrepare];
            }
        } else {
            // Switch to previous song.
            BOOL wasPlaying = self.isPlaying;
            [self switchToQueueIndex:self.root.currentQueueIndex-1];
            if (wasPlaying) {
                [self play];
            }
        }
    }    
}

- (void)beginSeekingForward
{
    if (self.isPlaying) {
        self.seekTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                          target:self
                                                        selector:@selector(seekForwardTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];
        if (self.nextPlayer) {
            [self.nextPlayer stop];
            self.nextPlayer = nil;
        }
    }
}

- (void)beginSeekingBackward
{
    if (self.isPlaying) {
        self.seekTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                          target:self
                                                        selector:@selector(seekBackwardsTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];
        if (self.nextPlayer) {
            [self.nextPlayer stop];
            self.nextPlayer = nil;
        }
    }
}

- (void)endSeekingForward
{
    [self nextPlayerPrepare];
    [self.seekTimer invalidate];
    self.seekTimer = nil;
}

- (void)endSeekingBackward
{
    [self nextPlayerPrepare];
    [self.seekTimer invalidate];
    self.seekTimer = nil;
}

static NSTimeInterval seekAmount = 2.0;

- (void)seekForwardTimerFired:(NSTimer *)timer
{
    if (self.currentPlayer) {
        self.currentPlayer.currentTime += seekAmount;
    }
}

- (void)seekBackwardsTimerFired:(NSTimer *)timer
{
    if (self.currentPlayer) {
        self.currentPlayer.currentTime -= seekAmount;
    }
}

/****************************************************************************/
#pragma mark - Queue Methods
/****************************************************************************/
// High-level commands.  These will save to db when done.
- (void)clearQueue
{
    NSLog(@"Clearing queue and stopping.");
    // XXX Does this send DidFinishPlaying?
    [self stop];
    self.currentPlayer = nil;
    self.nextPlayer = nil;

    // Clear the queue.
    NSArray *oldEnts = [NSArray arrayWithArray:self.root.queue.entries];
    [self.root.queue removeAllEntries];
    for (EPEntry *ent in oldEnts) {
        [ent checkForOrphan];
    }
    [self softUpdateCurrentQueueIndex:0];
    [self saveQueue];
    
    [self.tableView reloadData];
    [self updateDisplay];
}

- (void)switchToQueueIndex:(NSInteger)index
{
    [self stop];
    [self softUpdateCurrentQueueIndex:index];
    [self setCurrentPlayer];
    [self updateDisplay];
}

// Update the index without affecting the player.
- (void)softUpdateCurrentQueueIndex:(NSInteger)index
{
    self.root.currentQueueIndex = index;
    [self updateDisplay];
}

- (void)playEntry:(EPEntry *)entry;
{
    [self clearQueue];
    [self appendEntry:entry];
    [self play];
}

- (void)appendEntry:(EPEntry *)entry
{
    [self dbAppendEntry:entry];
    [self saveQueue];
    [self.mainTabController reloadBrowsers];
}


// Low-level queue commands.
- (void)saveQueue
{
    [EPRoot sharedRoot].dirty = YES;
}

- (void)dbAppendEntry:(EPEntry *)entry
{
    if ([entry.class isSubclassOfClass:[EPFolder class]]) {
        EPFolder *folder = (EPFolder *)entry;
        for (EPEntry *child in folder.sortedEntries) {
            [self dbAppendEntry:child];
        }
        [folder propagatePlayCount:1];
        [folder propagatePlayDate:[NSDate date]];
    } else {
        // is Song type.
        [self.root.queue addEntriesObject:entry];
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.root.queue.entries.count-1 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:YES];
    }
}

/****************************************************************************/
#pragma mark - Notifications
/****************************************************************************/

- (void)registerNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    // I can't get this one to work, use MediaPlayer instead.
//    [notificationCenter addObserver:self
//                           selector:@selector(volumeChanged:)
//                               name:@"AVSystemController_SystemVolumeDidChangeNotification"
//                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(volumeChanged:)
                               name:MPMusicPlayerControllerVolumeDidChangeNotification
                             object:self.mpPlayer];
    [notificationCenter addObserver:self
                           selector:@selector(libraryChanged:)
                               name:MPMediaLibraryDidChangeNotification
                             object:self.mpPlayer];
//xxx
    [self.mpPlayer beginGeneratingPlaybackNotifications];
    
    // App state notifications.
    [notificationCenter addObserver:self
                           selector:@selector(willResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(didBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];


	AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     (__bridge void *)(self)
                                     );

}

- (void)willResignActive:(UIApplication *)application
{
    NSLog(@"PLAYER Resigning");
    [self stopTimer];
    self.isDisplayed = NO;
}

- (void)didBecomeActive:(UIApplication *)application
{
    NSLog(@"PLAYER Become active");
    if (self.mainTabController.selectedViewController == self) {
        self.isDisplayed = YES;
        [self updateDisplay];
    }
}

/****************************************************************************/
#pragma mark - Display Update
/****************************************************************************/

- (void)switchToPreviousTab
{
    // Queue is currently displayed, and the previous tab was not the queue.
    // (I don't think the check for previous==self is necessary.)
    if (self.mainTabController.previousController &&
        self.mainTabController.previousController != self &&
        self.mainTabController.selectedViewController == self) {
        self.mainTabController.selectedViewController = self.mainTabController.previousController;
    }
}

- (void)updateNowPlayingInfoCenter
{
    if (self.isPlaying) {
        EPSong *song = self.root.queue.entries[self.root.currentQueueIndex];
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
        [info ep_setOptObject:song.mediaWrapper.albumTitle forKey:MPMediaItemPropertyAlbumTitle];
        [info ep_setOptObject:song.mediaWrapper.artist forKey:MPMediaItemPropertyArtist];
        [info ep_setOptObject:song.mediaWrapper.artwork forKey:MPMediaItemPropertyArtwork];
        [info ep_setOptObject:song.persistentID forKey:MPMediaItemPropertyPersistentID];
        [info ep_setOptObject:[song.mediaItem valueForProperty:MPMediaItemPropertyPlaybackDuration] forKey:MPMediaItemPropertyPlaybackDuration];
        [info ep_setOptObject:song.name forKey:MPMediaItemPropertyTitle];
        [info ep_setOptObject:@(self.currentPlayer.currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [info ep_setOptObject:@(self.root.currentQueueIndex) forKey:MPNowPlayingInfoPropertyPlaybackQueueIndex];
        [info ep_setOptObject:@(self.root.queue.entries.count) forKey:MPNowPlayingInfoPropertyPlaybackQueueCount];
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
    } else {
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    }

}

- (void)updateDisplay
{
    if (self.isDisplayed) {
        [self updateNowPlayingView];
        if (self.isPlaying) {
            [self.playButton setImage:[UIImage imageNamed:@"queue-pause"] forState:UIControlStateNormal];
            [self startTimer];
        } else {
            [self.playButton setImage:[UIImage imageNamed:@"queue-play"] forState:UIControlStateNormal];
            [self stopTimer];
        }
    }
}

- (void)updateNowPlayingView
{
    if (self.root.queue.entries.count) {
        EPSong *song = self.root.queue.entries[self.root.currentQueueIndex];
        [self.trackSummary loadSong:song];
        if (self.isPlaying) {
            // Make sure the scrubber is updating.
            [self startTimer];
        }
    } else {
        // Empty queue.
        [self.trackSummary loadSong:nil];
    }
    [self updateScrubber];
    [self updateCurrentPlayingCell];
}

- (void)updateCurrentPlayingCell
{
    // First clear.
    for (EPPlayerCellView *cell in self.tableView.visibleCells) {
        [cell unsetCurrent];
    }
    if (self.root.queue.entries.count) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.root.currentQueueIndex inSection:0];
        EPPlayerCellView *cell = (EPPlayerCellView *)[self.tableView cellForRowAtIndexPath:path];
        if (cell) {
            [cell setCurrent:self.isPlaying];
        }
    }
    [self scrollToCurrent];
}

- (void)scrollToCurrent
{
    if (self.isDisplayed && self.root.queue.entries.count) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.root.currentQueueIndex inSection:0];
        if (![self.tableView.indexPathsForVisibleRows containsObject:path]) {
            // It is currently not visible, scroll to it.
            [self.tableView scrollToRowAtIndexPath:path
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:YES];
        }
        
    }
}

- (void)updateTimeLabels
{
    if (self.currentPlayer) {
        int time = self.currentPlayer.currentTime;
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%i:%02i",
                                      time/60, time%60];
        
        NSTimeInterval duration = self.currentPlayer.duration;
        int timeLeft = duration - self.currentPlayer.currentTime;
        
        self.timeLeftLabel.text = [NSString stringWithFormat:@"-%i:%02i",
                                   timeLeft/60,
                                   timeLeft%60];
    } else {
        self.currentTimeLabel.text = @"0:00";
        self.timeLeftLabel.text = @"0:00";
    }

}

- (void)updateScrubber
{
    [self updateTimeLabels];
    if (self.currentPlayer) {
        NSTimeInterval duration = self.currentPlayer.duration;
        [self.scrubber setValue:self.currentPlayer.currentTime/duration animated:YES];
    } else {
        [self.scrubber setValue:0 animated:YES];
    }
}

- (void)startTimer
{
    if (self.timer == nil && self.isDisplayed) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(timerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
        self.scrubberManualUpdating = NO;
    }
}

- (void)stopTimer
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)timerFired:(NSTimer *)timer
{
//    NSLog(@"timer fired %@", self.isDisplayed ? @"YES" : @"NO");
    if (self.isDisplayed) {
        if (self.scrubberManualUpdating) {
            [self updateTimeLabels];
        } else {
            [self updateScrubber];
        }
    }
}

// This doesn't work too well (the offset is just too far off).
// Also, would need to disable when you scroll, defeating its purpose.
//- (void)scrollLyrics
//{
//    if (!self.lyricView.hidden) {
//        NSTimeInterval duration = self.currentPlayer.duration;
//        CGFloat proportion = self.currentPlayer.currentTime/duration;
//        CGFloat y = self.lyricView.contentSize.height*proportion;
//        [self.lyricView scrollRectToVisible:CGRectMake(0, y, 1, 1) animated:YES];
//    }
//}

/****************************************************************************/
#pragma mark - AVAudioPlayer Delegate
/****************************************************************************/

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"%@ Did finish: %i", player, (int)flag);
    if (flag) {
        EPSong *finishedSong = self.root.queue.entries[self.root.currentQueueIndex];
        if (self.root.currentQueueIndex < self.root.queue.entries.count-1) {
            // Prepare for the next track to play.
            [self softUpdateCurrentQueueIndex:self.root.currentQueueIndex+1];
            if (self.nextPlayer) {
                // Assume nextPlayer will pick up.
                self.currentPlayer = self.nextPlayer;
                if (self.root.currentQueueIndex < self.root.queue.entries.count-1) {
                    // Prepare the next track.
                    self.nextPlayer = [self playerForIndex:self.root.currentQueueIndex+1];
                    [self nextPlayerPrepare];
                } else {
                    // No next track.
                    self.nextPlayer = nil;
                }
            } else {
                // This can happen if entries are added to the queue while playing
                // the last entry.  Could fix the queue commands, but that's a
                // rare case.
                self.isPlaying = NO;  // setCurrentPlayer requires this.
                [self setCurrentPlayer];
                [self play];
            }
        } else {
            // At the end of the queue.
            self.currentPlayer = nil;
            self.nextPlayer = nil;  // Probably redundant.
            self.root.currentQueueIndex = 0;
            [self switchToPreviousTab];
            [self setPlayingIsStopped];
        }
        finishedSong.playCount += 1;
        finishedSong.playDate = [NSDate date];
        [self saveQueue];
    } else {
        // Decode failure.
        if (self.nextPlayer) {
            [self.nextPlayer stop];
            self.nextPlayer = nil;
        }
        [self setPlayingIsStopped];
    }
    [self updateDisplay];
    [self updateNowPlayingInfoCenter];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode error: %@", error);
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    NSLog(@"Begin interruption.");
    // Automatically paused.
    if (self.isPlaying) {
        self.interruptedWhilePlaying = YES;
        [self setPlayingIsStopped];
    }
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags
{
    NSLog(@"End interruption.");
    // Unpause.
    if (self.interruptedWhilePlaying) {
        self.interruptedWhilePlaying = NO;
        [self play];
    }
}

- (void)volumeChanged:(id)notification
{
    [self updateVolumeImage];
}

- (void)libraryChanged:(id)notification
{
    // This never seems to be called.
    NSLog(@"Library changed.");
}

/****************************************************************************/
#pragma mark - Volume
/****************************************************************************/
- (float)volume
{
    return self.mpPlayer.volume;
    // An alternative.
//    Float32 volume;
//    UInt32 dataSize = sizeof(Float32);
//    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputVolume,
//                            &dataSize, &volume);
//    return volume;
}


- (void)updateVolumeImage
{
    UIImage *on = [UIImage imageNamed:@"queue-volume-on"];
    UIImage *off = [UIImage imageNamed:@"queue-volume-off"];

    UIGraphicsBeginImageContextWithOptions(on.size, NO, 0.0);
    CGFloat width = on.size.width*self.volume;
    on = [on crop:CGRectMake(0, 0, width, on.size.height)];
    off = [off crop:CGRectMake(width, 0, off.size.width-width, off.size.height)];
    [on drawAtPoint:CGPointMake(0, 0)];
    [off drawAtPoint:CGPointMake(width, 0)];
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.tabBarItem setFinishedSelectedImage:result
                  withFinishedUnselectedImage:result];
}

/****************************************************************************/
#pragma mark - Remote Control
/****************************************************************************/
- (void)handleRemoteControlEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlNextTrack:
                [self nextTrack];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [self pause];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [self play];
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self prevTrack];
                break;
                
            case UIEventSubtypeRemoteControlStop:
                [self stop];
                break;
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (self.isPlaying) {
                    [self pause];
                } else {
                    [self play];
                }
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                [self beginSeekingBackward];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                [self beginSeekingForward];
                break;

            case UIEventSubtypeRemoteControlEndSeekingBackward:
                [self endSeekingBackward];
                break;

            case UIEventSubtypeRemoteControlEndSeekingForward:
                [self endSeekingForward];
                break;

            default:
                break;
        }
    }
    
}

@end
