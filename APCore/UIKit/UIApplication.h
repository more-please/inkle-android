#pragma once

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

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
- (int) versionCode;

- (BOOL) isPartInstalled:(int)part;
- (void) openPart:(int)part;

- (BOOL) canTweet;
- (void) tweet:(NSString*)text url:(NSString*)url image:(NSString*)image;

// Rather specific to 80 Days...
typedef void (^NameResultBlock)(NSString *chosenName); // nil chosen name == cancel
- (void) shareJourneyWithName:(NSString*)existingName block:(NameResultBlock)block;

- (void) mailTo:(NSString*)to message:(NSString*)message attachment:(NSString*)path;

- (void) quit;

#ifdef ANDROID
// Wrappers for Parse.
// TODO (URGENT!) - split these off from SorceryActivity.
- (JNIEnv*) jniEnv;
- (jobject) jniContext;
- (jclass) jniFindClass:(NSString*)name;

- (void) parseInitWithApplicationId:(NSString*)applicationId clientKey:(NSString*)clientKey;
- (void) parseCallFunction:(NSString*)function parameters:(NSDictionary*)parameters block:(PFIdResultBlock)block;

- (jobject) parseNewObject:(NSString*)className;
- (jobject) parseNewObject:(NSString*)className objectId:(NSString*)objectId;
- (NSString*) parseObjectId:(jobject)jobj;
- (void) parseObject:(jobject)obj addKey:(NSString*)key value:(id)value;
- (void) parseObject:(jobject)obj removeKey:(NSString*)key;
- (void) parseObject:(jobject)obj saveWithBlock:(PFBooleanResultBlock)block;
- (void) parseObject:(jobject)obj saveEventuallyWithBlock:(PFBooleanResultBlock)block;
- (void) parseObject:(jobject)obj fetchWithBlock:(PFObjectResultBlock)block;
- (void) parseObject:(jobject)obj refreshWithBlock:(PFObjectResultBlock)block;

- (jobject) parseNewQuery:(NSString*)className;
- (void) parseQuery:(jobject)obj whereKey:(NSString*)key equalTo:(id)vaue;
- (void) parseQuery:(jobject)obj findWithBlock:(PFArrayResultBlock)block;

- (void) parseEnableAutomaticUser;
- (jobject) parseCurrentUser;

// Wrappers for Google Analytics
// TODO: again, would be nice to decouple these from SorceryActivity...
- (jobject) gaiTrackerWithTrackingId:(NSString*)trackingId;
- (jobject) gaiDefaultTracker;

- (jobject) gaiEventWithCategory:(NSString *)category
                          action:(NSString *)action
                           label:(NSString *)label
                           value:(NSNumber *)value;

- (void) gaiTracker:(jobject)tracker set:(NSString*)param value:(NSString*)value;
- (void) gaiTracker:(jobject)tracker send:(jobject)params;
#endif

@end
