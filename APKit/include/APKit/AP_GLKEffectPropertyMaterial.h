#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>

@interface AP_GLKEffectPropertyMaterial : NSObject {
@public
    GLKVector4 _ambientColor;
    GLKVector4 _diffuseColor;
    GLKVector4 _specularColor;
    GLKVector4 _emissiveColor;
    GLfloat    _shininess;
}

// Properties                                               // Default Values
@property (nonatomic, assign) GLKVector4 ambientColor;      // { 0.2, 0.2, 0.2, 1.0}
@property (nonatomic, assign) GLKVector4 diffuseColor;      // { 0.8, 0.8, 0.8, 1.0}
@property (nonatomic, assign) GLKVector4 specularColor;     // { 0.0, 0.0, 0.0, 1.0}
@property (nonatomic, assign) GLKVector4 emissiveColor;     // { 0.0, 0.0, 0.0, 1.0}
@property (nonatomic, assign) GLfloat    shininess;         // 0.0

@end
