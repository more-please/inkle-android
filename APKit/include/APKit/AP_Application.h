#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@class AP_Application;

@protocol AP_ApplicationDelegate <NSObject>
@end

@interface AP_Application : NSObject

+ (AP_Application*) sharedApplication;

@property(nonatomic,assign) id<AP_ApplicationDelegate> delegate;

- (BOOL) openURL:(NSURL*)url;
- (BOOL) canOpenURL:(NSURL*)url;

- (void) registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

@end
