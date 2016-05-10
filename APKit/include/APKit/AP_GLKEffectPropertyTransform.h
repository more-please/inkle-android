#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface AP_GLKEffectPropertyTransform : NSObject {
@public
    GLKMatrix4 _modelviewMatrix;
    GLKMatrix4 _projectionMatrix;
}

@property (nonatomic) GLKMatrix4 modelviewMatrix;
@property (nonatomic) GLKMatrix4 projectionMatrix;

@end
