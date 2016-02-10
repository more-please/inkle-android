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

- (BOOL) isPartInstalled:(int)part;
- (void) openPart:(int)part;

- (BOOL) canTweet;
- (void) tweet:(NSString*)text url:(NSString*)url image:(NSString*)image;

// Rather specific to 80 Days...
typedef void (^NameResultBlock)(NSString *chosenName); // nil chosen name == cancel
- (void) shareJourneyWithName:(NSString*)existingName block:(NameResultBlock)block;

- (void) mailTo:(NSString*)to message:(NSString*)message attachment:(NSString*)path;

- (void) quit;
- (void) fatalError:(NSString*)message;

@end
