#import "AP_GLTexture_KTX.h"

#import <CoreFoundation/CoreFoundation.h>

#import "AP_Check.h"

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

@implementation AP_GLTexture_KTX

+ (AP_GLTexture*) withData:(NSData *)data maxSize:(CGFloat)screens
{
    return [[AP_GLTexture_KTX alloc] initWithData:data maxSize:screens];
}

+ (BOOL) isKTX:(NSData *)data
{
    AP_CHECK(data, return NO);
    AP_CHECK([data length] >= sizeof(Header), return NO);

    const Header* header = (const Header*)[data bytes];
    return 0 == memcmp(header->magic, kMagic, 12);
}

AP_BAN_EVIL_INIT;

- (AP_GLTexture_KTX*) initWithData:(NSData *)data maxSize:(CGFloat)screens
{
    AP_CHECK([AP_GLTexture_KTX isKTX:data], return nil);

    self = [super initMaxSize:screens];
    if (self) {
        const Header* header = (const Header*)[data bytes];

        // The header has an endianness flag, how weird.
        uint32_t (*read32)(uint32_t);
        if (header->endianness == CFSwapInt32LittleToHost(kEndianness)) {
            read32 = CFSwapInt32LittleToHost;
        } else if (header->endianness == CFSwapInt32BigToHost(kEndianness)) {
            read32 = CFSwapInt32BigToHost;
        } else {
            AP_LogError("Bad endianness flag: 0x%x", header->endianness);
            return nil;
        }

        GLenum format = read32(header->glFormat);
        GLenum internalFormat = read32(header->glInternalFormat);

        int width = read32(header->pixelWidth);
        int height = read32(header->pixelHeight);

        // We currently support compressed textures and UNSIGNED_BYTE textures.
        GLenum type = read32(header->glType);
        uint32_t typeSize = read32(header->glTypeSize);
        AP_CHECK(typeSize == 0 || typeSize == 1, return nil);
        AP_CHECK(type == 0 || type == GL_UNSIGNED_BYTE, return nil);

        // We don't support array textures or cube textures.
        int numArrayElements = MAX(1, read32(header->numberOfArrayElements));
        int numFaces = MAX(1, read32(header->numberOfFaces));
        AP_CHECK_EQ(numArrayElements, 1, return nil);
        AP_CHECK_EQ(numFaces, 1, return nil);

        // Skip header and key-value metadata.
        const char* bytes = [data bytes];
        bytes += sizeof(Header);
        bytes += read32(header->bytesOfKeyValueData);

        const char* maxBytes = bytes + [data length];
        AP_CHECK(maxBytes > bytes, return nil);

        int numLevels = MAX(1, read32(header->numberOfMipmapLevels));
        for (int level = 0; level < numLevels; ++level) {
            AP_CHECK((bytes + 4) <= maxBytes, return nil);
            int dataSize = read32(*(uint32_t*) bytes);
            bytes += 4;

            AP_CHECK(dataSize > 0, return nil);
            AP_CHECK((bytes + dataSize) <= maxBytes, return nil);

            if (type == 0) {
                [self compressedTexImage2dLevel:level format:internalFormat width:width height:height data:bytes dataSize:dataSize];
            } else {
                [self texImage2dLevel:level format:format width:width height:height type:type data:bytes];
            }
            AP_CHECK_GL("Failed to upload texture", return nil);

            width = MAX(1, width >> 1);
            height = MAX(1, height >> 1);

            dataSize = (dataSize + 3) & ~3;
            bytes += dataSize;
        }

        if (read32(header->numberOfMipmapLevels) == 0) {
            _GL(GenerateMipmap, self.name);
            AP_CHECK_GL("Failed to generate mipmaps", return nil);
            self.memoryUsage = (4 * self.memoryUsage) / 3;
        }

        _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        if (numLevels > 1) {
            _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        } else {
            _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        }
        _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    return self;
}

@end
