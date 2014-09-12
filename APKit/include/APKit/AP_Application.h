#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"
#import "AP_Window.h"

@class AP_Application;

@protocol AP_ApplicationDelegate <NSObject>

- (BOOL) application:(AP_Application*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions;

@property (nonatomic,strong) UIWindow* window;

#if 0 // Sorcery-specific?
// Android-specific additions
- (void) addBackCloseBlock:(void(^)())backBlock;
- (void) removeLastBackButtonBlock;
- (BOOL) goBack; // Return YES if the event was handled.
#endif

@end

#ifdef ANDROID
@interface AP_Application : UIApplication
#else
@interface AP_Application : NSObject
#endif

+ (AP_Application*) sharedApplication;

@property(nonatomic,strong) id<AP_ApplicationDelegate> delegate;

// FIXME -- needs to be properly implemented!
@property(nonatomic,readonly) AP_Window *keyWindow;
@property(nonatomic) UIInterfaceOrientation statusBarOrientation;

- (BOOL) openURL:(NSURL*)url;
- (BOOL) canOpenURL:(NSURL*)url;

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

@end
