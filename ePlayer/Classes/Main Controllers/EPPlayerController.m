
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
#import "EPPlayerAVAudio.h"
#import "EPPlayerMPMusic.h"
#import "EPSettings.h"

/****************************************************************************/
#pragma mark - Implementation
/****************************************************************************/

@implementation EPPlayerController

- (void)mainInit
{
    self.mpPlayer = [MPMusicPlayerController applicationMusicPlayer];
    [self registerNotifications];
    [self updateVolumeImage];
    [self changeAudioBackend];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    // I think for the other tabs, the NavigationBar is forcing this
    // (probably because of the settings in the app plist).  Not sure if there
    // is a better, global way to set this
    // (set UIViewControllerBasedStatusBarAppearance to NO?).  Well, regardless
    // I need to redo the coloring anyways, this will fix the problem for now
    // (was getting black text on a black background).
    return UIStatusBarStyleLightContent;
}

- (EPMainTabController *)mainTabController
{
    return (EPMainTabController *)self.tabBarController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    return self.root.queue.songs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlayerCell";
    EPPlayerCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    EPSong *song = (EPSong *)self.root.queue.songs[indexPath.row];
    // Dunno why Xcode flip-flops the warning here, just force it with a cast.
    cell.queueNumLabel.text = [NSString stringWithFormat:@"%i.", (int)(indexPath.row+1)];
    cell.trackNameLabel.text = song.name;
    cell.albumNameLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                song.mediaWrapper.albumTitle,
                                song.mediaWrapper.albumArtist];
    int duration = (int)song.duration;
    cell.trackTimeLabel.text = [NSString stringWithFormat:@"%i:%02i",
                                 duration/60, duration%60];
    if (self.root.currentQueueIndex == indexPath.row) {
        [cell setCurrent:self.player.isPlaying];
    } else {
        [cell unsetCurrent];
    }
    [cell setEvenOdd:indexPath.row%2];
    return cell;
}

// This helps with performance.  iOS 8 (or 7?) introduced dynamic cell height.  It needs
// to know the height of all cells in order to draw the scroll bar.  However, by
// returning an estimated value, it only computes the exact height for visible
// cells, and uses this estimate for the rest (if it is not exact, that's OK,
// it's just a scroll bar).
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 44;
//}

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
    [self.player switchToQueueIndex:indexPath.row];
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
        [self.lyricView updateWithSong:(EPSong *)self.root.queue.songs[self.root.currentQueueIndex]];
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
    if (self.player.isPlaying) {
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
            [self.player beginSeekingBackward];
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self.player endSeeking];
            break;
            
        default:
            break;
    }
}

- (IBAction)heldNext:(UILongPressGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self.player beginSeekingForward];
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self.player endSeeking];
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
    // cast-to-int to use 1 second resolution.
    NSTimeInterval duration = (int)self.player.currentDuration;
    NSTimeInterval newPlaybackTime = duration*self.scrubber.value;
    // Only alter it if the change is >= 1 second.
    if ((int)newPlaybackTime != self.lastScrubberPlayTime) {
        self.lastScrubberPlayTime = (int)newPlaybackTime;
        self.lastScrubberUpdate = now;
        self.player.currentPlaybackTime = duration*self.scrubber.value;
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
    self.lastScrubberPlayTime = self.player.currentPlaybackTime;
}

- (IBAction)scrubberTouchUp:(id)sender
{
    self.scrubberManualUpdating = NO;
}


/****************************************************************************/
#pragma mark - Player Methods
/****************************************************************************/

- (void)playEntry:(EPEntry *)entry
{
    [self.player replaceQueue:entry];
    [self.tableView reloadData];
    [self play];
}
- (void)appendEntry:(EPEntry *)entry
{
    [self.player appendEntry:entry];
    [self.tableView reloadData];
    // TODO: I forget why this is needed.
    [self.mainTabController reloadBrowsers];
}

- (BOOL)shouldAppend
{
    // Was considering handling the situation where you are in the middle of
    // the queue, and you pause.  Perhaps it should return YES in that case?
    // It would require a "finishedPlaying" bool that is triggered when the
    // queue hits the end.  Alternatively, just check if at the very beginning
    // of the queue (and assume that only happens when the queue finishes,
    // which is not true in the case of appending to an empty queue).
    return self.player.isPlaying;
}

- (void)play
{
    [self.player play];
    [self updateDisplay];
    [[NSNotificationCenter defaultCenter] postNotificationName:kEPPlayNotification object:nil];
}

- (void)pause
{
    [self.player pause];
    [self updateDisplay];
}

- (void)nextTrack
{
    if (self.root.queue.songs.count) {
        if (self.root.currentQueueIndex == self.root.queue.songs.count-1) {
            [self.player stop];
            [self.player switchToQueueIndex:0];
            [self updateDisplay];
        } else {
            // Switch to next song.
            BOOL wasPlaying = self.player.isPlaying;
            [self.player switchToQueueIndex:self.root.currentQueueIndex+1];
            if (wasPlaying) {
                [self play];
            } else {
                [self updateDisplay];
            }
        }
    }    
}

- (void)prevTrack
{
    if (self.root.queue.songs.count) {
        if (self.root.currentQueueIndex == 0) {
            self.player.currentPlaybackTime = 0;
        } else {
            // Switch to previous song.
            BOOL wasPlaying = self.player.isPlaying;
            [self.player switchToQueueIndex:self.root.currentQueueIndex-1];
            if (wasPlaying) {
                [self play];
            } else {
                [self updateDisplay];
            }
        }
    }    
}

- (void)changeAudioBackend
{
    if (self.player) {
        [self.player shutdown];
    }
    self.player = [[EPPlayerAVAudio alloc] init];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *backend = [settings stringForKey:kEPSettingAudioBackend];
    if (backend && [backend compare:kEPAudioBackendMPMusic]==NSOrderedSame) {
        self.player = [[EPPlayerMPMusic alloc] init];
    } else {
        self.player = [[EPPlayerAVAudio alloc] init];
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

    // Internal notifications.
    [notificationCenter addObserver:self
                           selector:@selector(queueFinished:)
                               name:kEPQueueFinishedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playerUpdated:)
                               name:kEPPlayerUpdateNotification
                             object:nil];

    // App state notifications.
    [notificationCenter addObserver:self
                           selector:@selector(willResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(didBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];

    // Audio route changes.
    [notificationCenter addObserver:self
                           selector:@selector(routeChanged:)
                               name:AVAudioSessionRouteChangeNotification
                             object:nil];
    // Handle AVAudioSessionMediaServicesWereResetNotification too?
}

- (void)routeChanged:(NSNotification *)notification
{
    NSNumber *interruptionType = notification.userInfo[AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionReason = notification.userInfo[AVAudioSessionRouteChangeReasonKey];
    AVAudioSessionInterruptionType iType = interruptionType.unsignedIntegerValue;
    AVAudioSessionRouteChangeReason iReason = interruptionReason.unsignedIntegerValue;
//    NSLog(@"type=%lu reason=%lu", (unsigned long)iType, iReason);

    if (self.player.isPlaying) {
        switch (iType) {
            case AVAudioSessionInterruptionTypeBegan:
                break;
            case AVAudioSessionInterruptionTypeEnded:
                if (iReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
                    // Headset was unplugged, or device remove from dock that
                    // has audio output.  Must call on main thread since this
                    // may cause UI updates.
                    NSLog(@"Pausing due to route change.");
                    [self performSelectorOnMainThread:@selector(pause) withObject:nil waitUntilDone:NO];
                }
                break;
            default:
                break;
        }
    }
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

- (void)queueFinished:(NSNotification *)notification
{
    [self switchToPreviousTab];
}

- (void)playerUpdated:(NSNotification *)notification
{
    [self updateDisplay];
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


- (void)updateDisplay
{
//    NSLog(@"updateDisplay isDisplay=%i isPlaying=%i", (int)self.isDisplayed, (int)self.player.isPlaying);
    if (self.isDisplayed) {
        [self updateNowPlayingView];
        if (self.player.isPlaying) {
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
    if (self.root.queue.songs.count) {
        EPSong *song = (EPSong *)self.root.queue.songs[self.root.currentQueueIndex];
        [self.trackSummary loadSong:song];
        if (self.player.isPlaying) {
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
    if (self.root.queue.songs.count) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.root.currentQueueIndex inSection:0];
        EPPlayerCellView *cell = (EPPlayerCellView *)[self.tableView cellForRowAtIndexPath:path];
        if (cell) {
            [cell setCurrent:self.player.isPlaying];
        }
    }
    [self scrollToCurrent];
}

- (void)scrollToCurrent
{
    if (self.isDisplayed && self.root.queue.songs.count) {
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
    int time = self.player.currentPlaybackTime;
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%i:%02i",
                                  time/60, time%60];
    
    NSTimeInterval duration = self.player.currentDuration;
    int timeLeft = duration - time;
    
    self.timeLeftLabel.text = [NSString stringWithFormat:@"-%i:%02i",
                               timeLeft/60,
                               timeLeft%60];
}

- (void)updateScrubber
{
    [self updateTimeLabels];
    NSTimeInterval duration = self.player.currentDuration;
    if (duration) {
        [self.scrubber setValue:self.player.currentPlaybackTime/duration animated:YES];
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
#pragma mark - Volume
/****************************************************************************/
- (float)volume
{
    // Deprecated iOS 7.  Use MPVolumeView instead.
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
    result = [result imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.tabBarItem.image = result;
    self.tabBarItem.selectedImage = result;
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
                [self.player stop];
                break;
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (self.player.isPlaying) {
                    [self pause];
                } else {
                    [self play];
                }
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                [self.player beginSeekingBackward];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                [self.player beginSeekingForward];
                break;

            case UIEventSubtypeRemoteControlEndSeekingBackward:
                [self.player endSeeking];
                break;

            case UIEventSubtypeRemoteControlEndSeekingForward:
                [self.player endSeeking];
                break;

            default:
                break;
        }
    }
    
}

@end
