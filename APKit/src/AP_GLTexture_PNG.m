#import "AP_GLTexture_PNG.h"

#import "stb_image.h"

#import "AP_Check.h"

static char gPNGIdentifier[8] = "\x89PNG\r\n\x1A\n";

@implementation AP_GLTexture_PNG

+ (AP_GLTexture*) withData:(NSData*)data
{
    return [[AP_GLTexture_PNG alloc] initWithData:data];
}

+ (BOOL) isPNG:(NSData *)data
{
    AP_CHECK(data, return NO);
    return ([data length] > 9) && (0 == memcmp([data bytes], gPNGIdentifier, 8));
}

AP_BAN_EVIL_INIT;

- (AP_GLTexture_PNG*) initWithData:(NSData *)data
{
    AP_CHECK([AP_GLTexture_PNG isPNG:data], return nil);
    self = [super init];
    if (self) {
        int w, h, components;
        unsigned char* bytes = stbi_load_from_memory([data bytes], [data length], &w, &h, &components, 0);
        AP_CHECK(bytes, return nil);
        
        GLenum format;
        if (components == 1) {
            format = GL_LUMINANCE;
        } else if (components == 2) {
            format = GL_LUMINANCE_ALPHA;
        } else if (components == 3) {
            format = GL_RGB;
        } else if (components == 4) {
            format = GL_RGBA;
        } else {
            AP_LogError("Expected 1-4 components in PNG file, found %d", components);
            return nil;
        }

        [self texImage2dLevel:0 format:format width:w height:h type:GL_UNSIGNED_BYTE data:(const char*)bytes];
        stbi_image_free(bytes);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

        glGenerateMipmap(GL_TEXTURE_2D);
        self.memoryUsage = (4 * self.memoryUsage) / 3;
        
        AP_CHECK_GL("Failed to upload PNG texture", return nil);
    }
    return self;
}

@end
