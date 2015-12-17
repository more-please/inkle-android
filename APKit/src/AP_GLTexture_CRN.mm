#import "AP_GLTexture_CRN.h"

#import <CoreFoundation/CoreFoundation.h>

#import "AP_Check.h"

#import "

// See http://www.khronos.org/opengles/sdk/tools/KTX/file_format_spec/

const uint32_t kEndianness = 0x04030201;

const uint8_t kMagic[12] = {
   0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A
};

typedef struct Header
{
    uint8_t magic[12];
    uint32_t endianness;
    uint32_t glType;
    uint32_t glTypeSize;
    uint32_t glFormat;
    uint32_t glInternalFormat;
    uint32_t glBaseInternalFormat;
    uint32_t pixelWidth;
    uint32_t pixelHeight;
    uint32_t pixelDepth;
    uint32_t numberOfArrayElements;
    uint32_t numberOfFaces;
    uint32_t numberOfMipmapLevels;
    uint32_t bytesOfKeyValueData;
} Header;

@implementation AP_GLTexture (KTX)

+ (BOOL) isKTX:(NSData *)data
{
    AP_CHECK(data, return NO);
    AP_CHECK([data length] >= cCRNHeaderMinSize, return NO);

    const Header* header = (const Header*)[data bytes];
    return 0 == memcmp(header->magic, kMagic, 12);
}

- (BOOL) loadKTX:(NSData*)data maxSize:(CGFloat)screens
{
    static GLint systemMaxTextureSize = 0;
    static GLint systemMaxCubeTextureSize = 0;
    if (systemMaxTextureSize == 0) {
        _GL(GetIntegerv, GL_MAX_TEXTURE_SIZE, &systemMaxTextureSize);
        _GL(GetIntegerv, GL_MAX_CUBE_MAP_TEXTURE_SIZE, &systemMaxCubeTextureSize);
    }
    if (systemMaxTextureSize == 0) {
        NSLog(@"*** glGetIntegerv(GL_MAX_TEXTURE_SIZE) returned 0 -- weird!");
        systemMaxTextureSize = 2048; // Should be safe
        systemMaxCubeTextureSize = 2048;
    }
    GLint maxTextureSize = self.cube ? systemMaxCubeTextureSize : systemMaxTextureSize;
#ifdef ANDROID
    CGSize s = [AP_Window screenSize];
    CGFloat screenSize = MAX(s.width, s.height) * [AP_Window screenScale];
    if (screenSize > 0) {
        CGFloat screenMaxTextureSize = screenSize * screens;
        maxTextureSize = MIN(maxTextureSize, screenMaxTextureSize);
    } else {
        NSLog(@"*** screenSize is 0 -- weird!");
    }
#endif

    const Header* header = (const Header*)[data bytes];

    // The header has an endianness flag, how weird.
    uint32_t (*read32)(uint32_t);
    if (header->endianness == CFSwapInt32LittleToHost(kEndianness)) {
        read32 = CFSwapInt32LittleToHost;
    } else if (header->endianness == CFSwapInt32BigToHost(kEndianness)) {
        read32 = CFSwapInt32BigToHost;
    } else {
        AP_LogError("Bad endianness flag: 0x%x", header->endianness);
        return NO;
    }

    GLenum format = read32(header->glFormat);
    GLenum internalFormat = read32(header->glInternalFormat);

    int width = read32(header->pixelWidth);
    int height = read32(header->pixelHeight);

    GLenum type = read32(header->glType);
    uint32_t typeSize = read32(header->glTypeSize);
    AP_CHECK(typeSize >= 0 && typeSize <= 4, return NO);

    // We don't support array textures or cube textures.
    int numArrayElements = MAX(1, read32(header->numberOfArrayElements));
    int numFaces = MAX(1, read32(header->numberOfFaces));
    AP_CHECK_EQ(numArrayElements, 1, return NO);
    AP_CHECK_EQ(numFaces, 1, return NO);

    // Skip header and key-value metadata.
    const char* bytes = [data bytes];
    bytes += sizeof(Header);
    bytes += read32(header->bytesOfKeyValueData);

    const char* maxBytes = bytes + [data length];
    AP_CHECK(maxBytes > bytes, return NO);

    int numLevels = MAX(1, read32(header->numberOfMipmapLevels));
    int level = 0;
    for (int i = 0; i < numLevels; ++i) {
        AP_CHECK((bytes + 4) <= maxBytes, return NO);
        int dataSize = read32(*(uint32_t*) bytes);
        bytes += 4;

        AP_CHECK(dataSize > 0, return NO);
        AP_CHECK((bytes + dataSize) <= maxBytes, return NO);

        if ((i+1 < numLevels) && (width > maxTextureSize || height > maxTextureSize)) {
            NSLog(@"Skipping mipmap level %d (width %d, height %d, max %d)", i, width, height, maxTextureSize);
        } else {
            if (type == 0) {
                [self compressedTexImage2dLevel:level format:internalFormat width:width height:height data:bytes dataSize:dataSize];
            } else {
                [self texImage2dLevel:level format:format width:width height:height type:type data:bytes];
            }
            ++level;
            AP_CHECK_GL("Failed to upload texture", return NO);
        }

        if (read32(header->numberOfMipmapLevels) == 0) {
            _GL(GenerateMipmap, self.textureTarget);
            AP_CHECK_GL("Failed to generate mipmaps", return NO);
            self.memoryUsage += dataSize / 3;
        }

        width = MAX(1, width >> 1);
        height = MAX(1, height >> 1);

        dataSize = (dataSize + 3) & ~3;
        bytes += dataSize;
    }

    _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    if (level > 1) {
        _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    } else {
        _GL(TexParameteri, self.textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    }

    return YES;
}

@end
