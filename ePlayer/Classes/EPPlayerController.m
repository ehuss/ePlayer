//
//  PlayerController.m
//  ePlayer
//
//  Created by Eric Huss on 4/12/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPPlayerController.h"

@interface EPPlayerController ()

@end

@implementation EPPlayerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Scrubber.
    self.scrubber = [[UISlider alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-80,
                                                               self.view.frame.size.width, 200)];
    self.scrubber.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrubber setThumbImage:[UIImage imageNamed:@"Images/scrubber-thumb"] forState:UIControlStateNormal];
	UIImage *scrubberTrackImage = [UIImage imageNamed:@"Images/scrubber-track"];
    UIImage *minTrack = [scrubberTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 25, 20)];
    UIImage *maxTrack = [scrubberTrackImage resizableImageWithCapInsets:UIEdgeInsetsMake(20, 0, 25, 20)];
    //- (UIImage *)resizableImageWithCapInsets:(UIEdgeInsets)capInsets
    [self.scrubber setMinimumTrackImage:minTrack forState:UIControlStateNormal];
    [self.scrubber setMaximumTrackImage:maxTrack forState:UIControlStateNormal];
    [self.view addSubview:self.scrubber];
    
    // The buttons.
    CGRect vf = self.view.frame;
    CGRect sf = self.scrubber.frame;
    self.prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.prevButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.prevButton setImage:[UIImage imageNamed:@"Images/queue-prev"] forState:UIControlStateNormal];
    [self.prevButton sizeToFit];
//    self.prevButton.frame = CGRectMake(0, vf.size.height-sf.size.height-44,
//                                       80, 44);
    [self.view addSubview:self.prevButton];
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playButton setImage:[UIImage imageNamed:@"Images/queue-play"] forState:UIControlStateNormal];
    [self.playButton sizeToFit];
//    self.playButton.frame = CGRectMake(80, vf.size.height-sf.size.height-44,
//                                       80, 44);
    [self.view addSubview:self.playButton];

    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nextButton setImage:[UIImage imageNamed:@"Images/queue-next"] forState:UIControlStateNormal];
    [self.nextButton sizeToFit];
//    self.nextButton.frame = CGRectMake(160, vf.size.height-sf.size.height-44,
//                                       80, 44);
    [self.view addSubview:self.nextButton];

    self.saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.saveButton setImage:[UIImage imageNamed:@"Images/queue-save"] forState:UIControlStateNormal];
    [self.saveButton sizeToFit];
//    self.saveButton.frame = CGRectMake(240, vf.size.height-sf.size.height-44,
//                                      80, 44);
    [self.view addSubview:self.saveButton];
    
    UIView *containerView = self.view;
    // setTranslatesAutoreszingMaskIntoConstraints:NO
//    NSDictionary *views = NSDictionaryOfVariableBindings(containerView,
//                                                         _scrubber,
//                                                         _prevButton,
//                                                         _playButton,
//                                                         _nextButton,
//                                                         _saveButton
//                                                         );
    // Scrubber at the bottom.
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.scrubber
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.view
                                  attribute:NSLayoutAttributeBottom
                                 multiplier:1 constant:0]];
    // Buttons in a row, left-to-right.
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.prevButton
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.view
                                  attribute:NSLayoutAttributeLeft
                                 multiplier:1 constant:0]];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.playButton
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.prevButton
                                  attribute:NSLayoutAttributeRight
                                 multiplier:1 constant:0]];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.nextButton
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.playButton
                                  attribute:NSLayoutAttributeRight
                                 multiplier:1 constant:0]];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.saveButton
                                  attribute:NSLayoutAttributeLeft
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.nextButton
                                  attribute:NSLayoutAttributeRight
                                 multiplier:1 constant:0]];
    // Buttons are just above the scrubber.
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.prevButton
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.scrubber
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:0]];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.playButton
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.scrubber
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:0]];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.nextButton
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.scrubber
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:0]];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:self.saveButton
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.scrubber
                                  attribute:NSLayoutAttributeTop
                                 multiplier:1 constant:0]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
