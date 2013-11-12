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
@property (strong, nonatomic) SVProgressHUD *progressHUD;
@property (nonatomic) NSString *hudString;
@property (nonatomic) NSDate *lastHudUpdate;
@property (assign, nonatomic) BOOL initializing;
@property (weak, nonatomic) NSObject *dbSender;
@property (weak, nonatomic) NSObject *initCompleteDelegate;

- (BOOL)loadData;
- (void)initDB:(NSObject *)completionDelegate;

- (void)beginDBUpdate:(NSObject *)sender;
- (void)resetDB;


@end
