#pragma once

#import <Foundation/Foundation.h>

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

@end
