#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "PVRTDecompress.h"
#include "stb_image_write.h"

#define PVR_TEXTURE_FLAG_TYPE_MASK	0xff

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

void usage() {
    fprintf(stderr,
        "Converts a .pvr file to .png format.\n\n"
        "Usage: pvr2png -i in.pvr -o out.png\n\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    const char* outfile = NULL;
    int width = 0, height = 0, bpp = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = argv[++i];
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }
    if (!infile || !outfile) {
        usage();
    }

    fprintf(stderr, "Reading %s\n", infile);
    FILE* f = fopen(infile, "rb");
    assert(f);

    fseek(f, 0, SEEK_END);
    int size = ftell(f);
    fseek(f, 0, SEEK_SET);

    char* input = (char*) malloc(size);
    size_t bytesRead = fread(input, 1, size, f);
    assert(bytesRead == size);
    assert(!ferror(f));
    fclose(f);

    PVRTexHeader* header = (PVRTexHeader*) input;
    PVRTexHeader* data = header + 1;
    uint32_t format = header->flags & PVR_TEXTURE_FLAG_TYPE_MASK;
    int w = header->width;
    int h = header->height;

    fprintf(stderr, "Width=%d, height=%d\nDecompressing...\n", w, h);
    unsigned char* output = (unsigned char*) malloc(w * h * 4);
    PVRTDecompressPVRTC(data, format == kPVRTextureFlagTypePVRTC_2, w, h, output);

    fprintf(stderr, "Writing %s\n", outfile);
    stbi_write_png(outfile, w, h, 4, output, w * 4);

    free(input);
    free(output);
    return 0;
}
