#pragma once

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

#define AP_SHADER_PREFIX \
    "#ifdef GL_FRAGMENT_PRECISION_HIGH\n" \
    "precision highp float;\n" \
    "#else\n" \
    "precision mediump float;\n" \
    "#endif\n"

#define AP_SHADER(...) (AP_SHADER_PREFIX #__VA_ARGS__)

@interface AP_GLProgram : NSObject

@property (readonly) GLuint name;

- (AP_GLProgram*) initWithVertex:(const char*)vertex fragment:(const char*)fragment;

- (GLint) attr:(NSString*)name;
- (GLint) uniform:(NSString*)name;
- (void) use;
- (BOOL) link;

@end
