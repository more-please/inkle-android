#import "AP_GLKTextureInfo.h"

#import "AP_GLTexture.h"

@implementation AP_GLKTextureInfo

- (GLuint) name
{
    return _tex.name;
}

- (GLuint) width
{
    return _tex.width;
}

- (GLuint) height
{
    return _tex.height;
}

@end
