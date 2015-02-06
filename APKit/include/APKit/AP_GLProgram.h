#pragma once

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

#define AP_SHADER(...) (#__VA_ARGS__)

@interface AP_GLProgram : NSObject

@property (readonly) GLuint name;

// If 'mask' is YES, we'll call 'discard' if the output alpha is low.
// This is expensive, but gives the correct results when drawing a mask stencil.
- (AP_GLProgram*) initWithVertex:(const char*)vertex fragment:(const char*)fragment mask:(BOOL)mask;

// mask=NO by default
- (AP_GLProgram*) initWithVertex:(const char*)vertex fragment:(const char*)fragment;

- (GLint) attr:(NSString*)name;
- (GLint) uniform:(NSString*)name;
- (void) use;
- (BOOL) link;

// Flag to control the global behaviour of 'use'.
// If YES, the 'use' method will use the masking version of each prog.
+ (BOOL) useMask:(BOOL)setUseMask; // Returns the previous value.

@end
