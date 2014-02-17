#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@class AP_Application;

@protocol AP_ApplicationDelegate <NSObject>

- (BOOL) application:(AP_Application*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions;

@property (nonatomic,strong) UIWindow* window;

// Android-specific additions
- (void) addBackCloseBlock:(void(^)())backBlock;
- (void) removeLastBackButtonBlock;
- (BOOL) goBack; // Return YES if the event was handled.

@end

@interface AP_Application : NSObject

+ (AP_Application*) sharedApplication;

@property(nonatomic,strong) id<AP_ApplicationDelegate> delegate;

- (BOOL) openURL:(NSURL*)url;
- (BOOL) canOpenURL:(NSURL*)url;

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

// Android-specific addition
@property(nonatomic,strong) NSString* documentsDir;

- (void) quit;

@end
