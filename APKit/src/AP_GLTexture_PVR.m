#import "AP_GLTexture_PVR.h"

#import <CoreFoundation/CoreFoundation.h>

#import "AP_Check.h"

#define PVR_TEXTURE_FLAG_TYPE_MASK 0xff

#ifndef GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG
#define GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG  0x8C00
#define GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG  0x8C01
#define GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG 0x8C02
#define GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG 0x8C03
#endif

static char gPVRTexIdentifier[4] = "PVR!";

enum
{
	kPVRTextureFlagTypePVRTC_2 = 24,
	kPVRTextureFlagTypePVRTC_4
};

typedef struct _PVRTexHeader
{
	uint32_t headerLength;
	uint32_t height;
	uint32_t width;
	uint32_t numMipmaps;
	uint32_t flags;
	uint32_t dataLength;
	uint32_t bpp;
	uint32_t bitmaskRed;
	uint32_t bitmaskGreen;
	uint32_t bitmaskBlue;
	uint32_t bitmaskAlpha;
	uint32_t pvrTag;
	uint32_t numSurfs;
} PVRTexHeader;

@implementation AP_GLTexture_PVR

+ (AP_GLTexture*) withData:(NSData*)data
{
    return [[AP_GLTexture_PVR alloc] initWithData:data];
}

+ (BOOL) isPVR:(NSData *)data
{
    AP_CHECK(data, return NO);
    AP_CHECK([data length] >= sizeof(PVRTexHeader), return NO);

    const PVRTexHeader* header = (const PVRTexHeader *)[data bytes];
    uint32_t pvrTag = CFSwapInt32LittleToHost(header->pvrTag);
    if (gPVRTexIdentifier[0] != ((pvrTag >>  0) & 0xff) ||
        gPVRTexIdentifier[1] != ((pvrTag >>  8) & 0xff) ||
        gPVRTexIdentifier[2] != ((pvrTag >> 16) & 0xff) ||
        gPVRTexIdentifier[3] != ((pvrTag >> 24) & 0xff))
    {
        return NO;
    }
    return YES;
}

AP_BAN_EVIL_INIT;

- (AP_GLTexture_PVR*) initWithData:(NSData *)data
{
    AP_CHECK([AP_GLTexture_PVR isPVR:data], return nil);
    
    self = [super init];
    if (self) {
        const PVRTexHeader* header = (const PVRTexHeader *)[data bytes];
        
        GLenum format;
        uint32_t bpp;

        uint32_t formatFlags = CFSwapInt32LittleToHost(header->flags) & PVR_TEXTURE_FLAG_TYPE_MASK;
        if (formatFlags == kPVRTextureFlagTypePVRTC_4) {
            format = GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
            bpp = 4;
        } else if (formatFlags == kPVRTextureFlagTypePVRTC_2) {
            format = GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
            bpp = 2;
        } else {
            AP_LogError("Unknown PVR format flag: %d", formatFlags);
            return nil;
        }
        
        uint32_t width = CFSwapInt32LittleToHost(header->width);
        uint32_t height = CFSwapInt32LittleToHost(header->height);
        uint32_t dataLength = CFSwapInt32LittleToHost(header->dataLength);

        const char* bytes = ((const char *)[data bytes]) + sizeof(PVRTexHeader);

        uint32_t dataOffset = 0;
        int level;
        for (level = 0; dataOffset < dataLength; ++level) {
            uint32_t blockSize, widthBlocks, heightBlocks, dataSize;

            if (formatFlags == kPVRTextureFlagTypePVRTC_4) {
                blockSize = 4 * 4; // Pixel by pixel block size for 4bpp
                widthBlocks = width / 4;
                heightBlocks = height / 4;
            } else {
                blockSize = 8 * 4; // Pixel by pixel block size for 2bpp
                widthBlocks = width / 8;
                heightBlocks = height / 4;
            }
            
            // Clamp to minimum number of blocks
            if (widthBlocks < 2) {
                widthBlocks = 2;
            }
            if (heightBlocks < 2) {
                heightBlocks = 2;
            }

            dataSize = widthBlocks * heightBlocks * ((blockSize  * bpp) / 8);

            [self compressedTexImage2dLevel:level format:format width:width height:height data:(bytes + dataOffset) dataSize:dataSize];
            
            dataOffset += dataSize;
            
            width = MAX(width >> 1, 1);
            height = MAX(height >> 1, 1);
        }

        _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        if (level > 1) {
            _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        } else {
            _GL(TexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        }
	}
    return self;
}

@end
