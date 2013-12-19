#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface AP_GLKEffectPropertyTransform : NSObject

@property (nonatomic) GLKMatrix4 modelviewMatrix;
@property (nonatomic) GLKMatrix4 projectionMatrix;

@end
