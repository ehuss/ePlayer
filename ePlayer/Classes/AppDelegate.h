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
#import "SVProgressHUD.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EPMainTabController *mainTabController;
@property (nonatomic) NSString *hudString;
@property (nonatomic) NSDate *lastHudUpdate;
@property (assign, nonatomic) BOOL initializing;
@property (weak, nonatomic) NSObject *dbSender;
@property (weak, nonatomic) NSObject *initCompleteDelegate;

// Returns true if the data is ready, false if it is being loaded
// in a background thread.
- (BOOL)loadData;
- (void)initDB:(NSObject *)completionDelegate;

// Scan the music database for new/removed/changed items.
// Runs in background, and sends a message
// `dbUpdateDone:(NSString *)results` to `sender` when it is finished.
- (void)beginDBUpdate:(NSObject *)sender;
// Completely deletes the database, starting a new one with no songs.
- (void)resetDB;

@end
