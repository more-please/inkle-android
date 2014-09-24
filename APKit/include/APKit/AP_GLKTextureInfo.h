#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>

@interface AP_GLKTextureInfo : NSObject

@property (nonatomic) GLuint name;
@property (nonatomic) GLuint width;
@property (nonatomic) GLuint height;

@end
