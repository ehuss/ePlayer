//
//  EPTrackSummaryView.h
//  ePlayer
//
//  Created by Eric Huss on 4/27/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPCommon.h"
#import "EPSong.h"

@interface EPTrackSummaryView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *albumArt;
@property (weak, nonatomic) IBOutlet UILabel *artistName;
@property (weak, nonatomic) IBOutlet UILabel *albumName;
@property (weak, nonatomic) IBOutlet UILabel *trackName;
@property (weak, nonatomic) IBOutlet UILabel *releasedDate;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UIButton *listButton;
@property (weak, nonatomic) IBOutlet UIView *flipButtonView;

- (void)loadSong:(EPSong *)song;

@end
