#pragma once

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

#import <jni.h>

@interface UIApplication : NSObject

+ (UIApplication*) sharedApplication;

// Android-specific additions
@property(nonatomic,strong) NSString* documentsDir;

- (void) quit;
- (NSData*) getResource:(NSString*)path;

- (JNIEnv*) jniEnv;
- (jobject) jniContext;
- (jclass) jniFindClass:(NSString*)name;

// Wrappers for Parse.
// TODO: split these off from SorceryActivity.
- (void) parseInitWithApplicationId:(NSString*)applicationId clientKey:(NSString*)clientKey;
- (void) parseCallFunction:(NSString*)function block:(PFIdResultBlock)block;
- (jobject) parseNewObject:(NSString*)className;
- (void) parseObject:(jobject)obj addKey:(NSString*)key value:(id)value;
- (void) parseObject:(jobject)obj saveWithBlock:(PFBooleanResultBlock)block;

@end
