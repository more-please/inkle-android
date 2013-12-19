#import "AP_GLKEffectPropertyTransform.h"

@implementation AP_GLKEffectPropertyTransform

- (id) init
{
    self = [super init];
    if (self) {
        _modelviewMatrix = GLKMatrix4Identity;
        _projectionMatrix = GLKMatrix4Identity;
    }
    return self;
}

- (void) setModelviewMatrix:(GLKMatrix4)modelviewMatrix
{
    _modelviewMatrix = modelviewMatrix;
}

- (void) setProjectionMatrix:(GLKMatrix4)projectionMatrix
{
    _projectionMatrix = projectionMatrix;
}

@end
