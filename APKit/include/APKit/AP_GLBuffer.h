#pragma once

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@interface AP_GLBuffer : NSObject

@property (readonly) GLuint name;

- (void) bind;
- (void) bufferTarget:(GLenum) target usage:(GLenum)usage data:(NSData*)data;
- (void) bufferTarget:(GLenum) target usage:(GLenum)usage data:(const void*)data size:(size_t)size;

+ (AP_GLBuffer*) bufferWithTarget:(GLenum)target usage:(GLenum)usage data:(NSData*)data;
+ (AP_GLBuffer*) bufferWithTarget:(GLenum)target usage:(GLenum)usage data:(const void*)data size:(size_t)size;

// Estimated total memory usage for all buffers.
+ (int) totalMemoryUsage;

+ (void) processDeleteQueue;

@end
