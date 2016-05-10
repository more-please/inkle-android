#import "AP_GLKEffectPropertyMaterial.h"

@implementation AP_GLKEffectPropertyMaterial

- (instancetype) init
{
    self = [super init];
    if (self) {
        _ambientColor = GLKVector4Make(0.2, 0.2, 0.2, 1);
        _diffuseColor = GLKVector4Make(0.8, 0.8, 0.8, 1);
        _specularColor = GLKVector4Make(0, 0, 0, 1);
        _emissiveColor = GLKVector4Make(0, 0, 0, 1);
        _shininess = 0;
    }
    return self;
}

@end
