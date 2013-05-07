//
//  AppDelegate.h
//  ePlayer
//
//  Created by Eric Huss on 4/9/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPMainTabController.h"
#import "EPPlayerController.h"
#import "EPRoot.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

- (BOOL)loadData;
- (void)initDB;

- (void)beginDBUpdate:(NSObject *)sender;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EPMainTabController *mainTabController;
@property (strong, nonatomic) UIAlertView *importAlertView;
@property (strong, nonatomic) UIProgressView *importProgressView;
@property (assign, nonatomic) BOOL initializing;
@property (weak, nonatomic) NSObject *dbSender;

@end
