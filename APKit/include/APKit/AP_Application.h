#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"
#import "AP_Window.h"

@class AP_Application;

@protocol AP_ApplicationDelegate <NSObject>

- (BOOL) application:(AP_Application*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions;

- (BOOL) application:(AP_Application *)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation;

@property (nonatomic,strong) Real_UIWindow* window;

// Android-specific additions
- (BOOL) handleAndroidBackButton; // Return YES if the event was handled.

@end

@interface AP_Application : UIApplication

+ (AP_Application*) sharedApplication;

@property(nonatomic,strong) id<AP_ApplicationDelegate> delegate;

@property(nonatomic,readonly) AP_Window *keyWindow;
@property(nonatomic,readonly) UIInterfaceOrientation statusBarOrientation;

- (BOOL) openURL:(NSURL*)url;
- (BOOL) canOpenURL:(NSURL*)url;

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

@end
