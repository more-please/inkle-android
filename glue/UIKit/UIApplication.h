#pragma once

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

#import <jni.h>

@interface UIApplication : NSObject

+ (UIApplication*) sharedApplication;

// Android-specific additions
@property(nonatomic,strong) NSString* documentsDir;
@property(nonatomic,strong) NSString* publicDocumentsDir;

- (void) quit;
- (NSData*) getResource:(NSString*)path;

- (JNIEnv*) jniEnv;
- (jobject) jniContext;
- (jclass) jniFindClass:(NSString*)name;

- (NSArray*) namesForResourcesOfType:(NSString*)ext inDirectory:(NSString*)dir;

// Wrappers for Parse.
// TODO: split these off from SorceryActivity.
- (void) parseInitWithApplicationId:(NSString*)applicationId clientKey:(NSString*)clientKey;
- (void) parseCallFunction:(NSString*)function block:(PFStringResultBlock)block;
- (jobject) parseNewObject:(NSString*)className;
- (void) parseObject:(jobject)obj addKey:(NSString*)key value:(id)value;
- (void) parseObject:(jobject)obj saveWithBlock:(PFBooleanResultBlock)block;

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

@end
