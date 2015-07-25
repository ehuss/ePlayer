//
//  EPPlayerAVAudio.h
//  ePlayer
//
//  Created by Eric Huss on 7/21/15.
//  Copyright (c) 2015 Eric Huss. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "EPPlayer.h"

@interface EPPlayerAVAudio : EPPlayer <AVAudioPlayerDelegate>

@property (nonatomic) AVAudioPlayer *currentPlayer;
@property (nonatomic) AVAudioPlayer *nextPlayer;
@property (nonatomic) NSTimer *seekTimer;
@property (nonatomic) BOOL interruptedWhilePlaying;

@end
