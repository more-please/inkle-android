#import "AP_GLKEffectPropertyLight.h"

@implementation AP_GLKEffectPropertyLight

- (instancetype) init
{
    self = [super init];
    if (self) {
        _position = GLKVector4Make(0, 0, 0, 1);
        _ambientColor = GLKVector4Make(0, 0, 0, 1);
        _diffuseColor = GLKVector4Make(1, 1, 1, 1);
        _specularColor = GLKVector4Make(1, 1, 1, 1);
    }
    return self;
}

- (void) setPosition:(GLKVector4)position
{
    _position = GLKVector4Normalize(position);
}

@end
