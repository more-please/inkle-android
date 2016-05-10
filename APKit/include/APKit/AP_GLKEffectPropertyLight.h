#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>

@interface AP_GLKEffectPropertyLight : NSObject {
@public
    GLboolean _enabled;
    GLKVector4 _position;
    GLKVector4 _ambientColor;
    GLKVector4 _diffuseColor;
    GLKVector4 _specularColor;
}

// Properties                                               // Default Value
@property (nonatomic, assign) GLboolean    enabled;         // GL_TRUE
@property (nonatomic, assign) GLKVector4   position;        // { 0.0, 0.0, 0.0, 1.0 }
@property (nonatomic, assign) GLKVector4   ambientColor;    // { 0.0, 0.0, 0.0, 1.0 }
@property (nonatomic, assign) GLKVector4   diffuseColor;    // { 1.0, 1.0, 1.0, 1.0 }
@property (nonatomic, assign) GLKVector4   specularColor;   // { 1.0, 1.0, 1.0, 1.0 }

@end
