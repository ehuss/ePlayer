//
//  PlayerController.m
//  ePlayer
//
//  Created by Eric Huss on 4/12/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "EPPlayerController.h"
#import "EPPlayerCellView.h"
#import "UIImage+EPCrop.h"
#import "EPMediaItemWrapper.h"
#import "EPMainTabController.h"
#import "EPRoot.h"

//static NSTimeInterval scrubberUpdateTime = 0.300;


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

- (EPFolder *)queueFolder
{
    if (_queueFolder == nil) {
        EPRoot *root = [EPRoot sharedRoot];
        _queueFolder = root.queue;
    }
    return _queueFolder;
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
    // There might be a way to do this from IB, but heck if I know.
    [self.trackSummary.infoButton addTarget:self
                                     action:@selector(tappedInfo:)
                           forControlEvents:UIControlEventTouchUpInside];
    [self.trackSummary.listButton addTarget:self
                                     action:@selector(tappedInfo:)
                           forControlEvents:UIControlEventTouchUpInside];
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
    return self.queueFolder.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlayerCell";
    EPPlayerCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    EPSong *song = self.queueFolder.entries[indexPath.row];
    cell.queueNumLabel.text = [NSString stringWithFormat:@"%i.", indexPath.row+1];
    cell.trackNameLabel.text = song.name;
    cell.albumNameLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                song.mediaWrapper.albumTitle,
                                song.mediaWrapper.albumArtist];
    int duration = (int)song.duration;
    cell.trackTimeLabel.text = [NSString stringWithFormat:@"%i:%02i",
                                 duration/60, duration%60];
    if (self.currentQueueIndex == indexPath.row) {
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
        [self.lyricView updateWithSong:self.queueFolder.entries[self.currentQueueIndex]];
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
    if (self.queueFolder.entries.count) {
        if (self.currentQueueIndex == 0) {
            // Set playback position to 0.
            if (self.currentPlayer) {
                self.currentPlayer.currentTime = 0;
                [self nextPlayerPrepare];
            }
        } else {
            // Switch to previous song.
            BOOL wasPlaying = self.isPlaying;
            [self switchToQueueIndex:self.currentQueueIndex-1];
            if (wasPlaying) {
                [self play];
            }
        }
    }
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
    if (self.queueFolder.entries.count) {
        if (self.currentQueueIndex == self.queueFolder.entries.count-1) {
            [self stop];
            [self switchToQueueIndex:0];
        } else {
            // Switch to next song.
            BOOL wasPlaying = self.isPlaying;
            [self switchToQueueIndex:self.currentQueueIndex+1];
            if (wasPlaying) {
                [self play];
            }
        }
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
        NSLog(@"updated to %f", self.currentPlayer.currentTime);
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
- (void)play
{
    NSLog(@"Play");
    if (!self.isPlaying && self.queueFolder.entries.count) {
        if (self.currentPlayer == nil) {
            [self setCurrentPlayer];
        }
        [self.currentPlayer play];
        [self nextPlayerPrepare];
        self.isPlaying = YES;
        [self updateDisplay];
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

- (AVAudioPlayer *)playerForIndex:(int)index
{
    EPSong *song = self.queueFolder.entries[index];
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
    self.currentPlayer = [self playerForIndex:self.currentQueueIndex];
    if (self.currentQueueIndex < self.queueFolder.entries.count-1) {
        self.nextPlayer = [self playerForIndex:self.currentQueueIndex+1];
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
        self.isPlaying = NO;
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
        self.isPlaying = NO;
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
    NSArray *oldEnts = [NSArray arrayWithArray:self.queueFolder.entries];
    [self.queueFolder removeAllEntries];
    for (EPEntry *ent in oldEnts) {
        [ent checkForOrphan];
    }
    [self softUpdateCurrentQueueIndex:0];
    [self saveQueue];
    
    [self.tableView reloadData];
    [self updateDisplay];
}

- (void)switchToQueueIndex:(int)index
{
    [self stop];
    [self softUpdateCurrentQueueIndex:index];
    [self setCurrentPlayer];
    [self updateDisplay];
}

// Update the index without affecting the player.
- (void)softUpdateCurrentQueueIndex:(int)index
{
    self.currentQueueIndex = index;
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
    [self.mainTabController resortPlayDates];
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
        if (![self.queueFolder.entries containsObject:entry]) {
            [self.queueFolder addEntriesObject:entry];
            NSIndexPath *path = [NSIndexPath indexPathForRow:self.queueFolder.entries.count-1 inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:YES];
        }
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
    self.isDisplayed = YES;
    if (self.isPlaying) {
        [self startTimer];
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
    if (self.queueFolder.entries.count) {
        EPSong *song = self.queueFolder.entries[self.currentQueueIndex];
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
    if (self.queueFolder.entries.count) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.currentQueueIndex inSection:0];
        EPPlayerCellView *cell = (EPPlayerCellView *)[self.tableView cellForRowAtIndexPath:path];
        if (cell) {
            [cell setCurrent:self.isPlaying];
        }
    }
    [self scrollToCurrent];
}

- (void)scrollToCurrent
{
    if (self.isDisplayed && self.queueFolder.entries.count) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.currentQueueIndex inSection:0];
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
    NSLog(@"timer fired %@", self.isDisplayed ? @"YES" : @"NO");
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
    NSLog(@"%@ Did finish: %hhd", player, flag);
    self.isPlaying = NO;
    if (flag) {
        EPSong *finishedSong = self.queueFolder.entries[self.currentQueueIndex];
        if (self.currentQueueIndex < self.queueFolder.entries.count-1) {
            // Prepare for the next track to play.
            [self softUpdateCurrentQueueIndex:self.currentQueueIndex+1];
            if (self.nextPlayer) {
                // Assume nextPlayer will pick up.
                self.currentPlayer = self.nextPlayer;
                if (self.currentQueueIndex < self.queueFolder.entries.count-1) {
                    // Prepare the next track.
                    self.nextPlayer = [self playerForIndex:self.currentQueueIndex+1];
                    [self nextPlayerPrepare];
                } else {
                    // No next track.
                    self.nextPlayer = nil;
                }
                self.isPlaying = YES;
            } else {
                // This can happen if entries are added to the queue while playing
                // the last entry.  Could fix the queue commands, but that's a
                // rare case.
                self.isPlaying = NO;
                [self setCurrentPlayer];
                [self play];
            }
        } else {
            // At the end of the queue.
            self.currentPlayer = nil;
            self.nextPlayer = nil;  // Probably redundant.
            self.currentQueueIndex = 0;
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
    }
    [self updateDisplay];
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
        self.isPlaying = NO;
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

@end
