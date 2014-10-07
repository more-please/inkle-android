#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>

@class AP_GLTexture;

@interface AP_GLKTextureInfo : NSObject

@property (readonly,nonatomic) GLuint name;
@property (readonly,nonatomic) GLuint width;
@property (readonly,nonatomic) GLuint height;

// Android-only
@property (nonatomic,strong) AP_GLTexture* tex;

@end
