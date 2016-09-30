#pragma once

#import <Foundation/Foundation.h>

#ifdef ANDROID
#import <jni.h>
#endif

@interface UIApplication : NSObject

+ (UIApplication*) sharedApplication;

// Android-specific additions
@property(nonatomic,strong) NSString* documentsDir;
@property(nonatomic,strong) NSString* publicDocumentsDir;
@property(nonatomic) BOOL isCrappyDevice;
@property(nonatomic, getter=isFullScreen) BOOL fullScreen;

- (BOOL) needsInitialSetup;

- (NSString*) versionName;
- (NSString*) googleAnalyticsId;

- (BOOL) isPartInstalled:(int)part;
- (void) openPart:(int)part;
- (int) defaultPart;

- (BOOL) canTweet;
- (void) tweet:(NSString*)text url:(NSString*)url image:(NSString*)image;

- (void) stayAwake; // Stop the screen auto-locking, on Android

// Rather specific to 80 Days...
typedef void (^NameResultBlock)(NSString *chosenName); // nil chosen name == cancel
- (void) shareJourneyWithName:(NSString*)existingName block:(NameResultBlock)block;

- (void) mailTo:(NSString*)to message:(NSString*)message attachment:(NSString*)path;

- (void) quit;
- (void) fatalError:(NSString*)message;

// Lock a mutex that prevents quitting (use during e.g. important file operations)
- (void) lockQuit;
- (void) unlockQuit;

// Register a file to be included in crash reports
- (void) addCrashReportPath:(NSString*)path description:(NSString*)desc;

@end
