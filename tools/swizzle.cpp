#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <algorithm>
#include <vector>

#include "stb_image.h"
#include "stb_image_write.h"

// Update the color of transparent pixels to be the average of nearby opaque pixels.
// This fixes mip-mapping artifacts such as color fringing.
void fix_alpha(int w, int h, unsigned char* data) {
    if (w <= 1 || h <= 1) {
        // Can't scale down any further, just ensure the alpha is non-zero.
        data[3] = 255;
    } else {
        // Scale the image down by a factor of 2, summing each 2x2 pixel block.
        int w2 = (w+1) / 2;
        int h2 = (h+1) / 2;
        std::vector<unsigned char> data2;
        data2.resize(w2 * h2 * 4);
        for (int y2 = 0; y2 < h2; ++y2) {
            for (int x2 = 0; x2 < w2; ++x2) {
                int r = 0, g = 0, b = 0, a = 0;
                for (int yOffset = 0; yOffset < 2; ++yOffset) {
                    for (int xOffset = 0; xOffset < 2; ++xOffset) {
                        int x = std::min(2 * x2 + xOffset, w - 1);
                        int y = std::min(2 * y2 + yOffset, h - 1);
                        int alpha = data[4 * (x + y * w) + 3];
                        r += alpha * data[4 * (x + y * w)];
                        g += alpha * data[4 * (x + y * w) + 1];
                        b += alpha * data[4 * (x + y * w) + 2];
                        a += alpha;
                    }
                }
                if (a == 0) {
                    r = g = b = 0;
                    a = 1;
                }
                data2[4 * (x2 + y2 * w2)] = r / a;
                data2[4 * (x2 + y2 * w2) + 1] = g / a;
                data2[4 * (x2 + y2 * w2) + 2] = b / a;
                data2[4 * (x2 + y2 * w2) + 3] = a / 4;
            }
        }

        // Fix alpha in the reduced image.
        fix_alpha(w2, h2, &data2[0]);

        // Use the reduced image to fill in gaps in the full-size image.
        for (int y = 0; y < h; ++y) {
            for (int x = 0; x < w; ++x) {
                int x2 = x / 2;
                int y2 = y / 2;
                unsigned char r2 = data2[4 * (x2 + y2 * w2)];
                unsigned char g2 = data2[4 * (x2 + y2 * w2) + 1];
                unsigned char b2 = data2[4 * (x2 + y2 * w2) + 2];
                unsigned char& r = data[4 * (x + y * w)];
                unsigned char& g = data[4 * (x + y * w) + 1];
                unsigned char& b = data[4 * (x + y * w) + 2];
                unsigned char& a = data[4 * (x + y * w) + 3];
                int k = (255 - a);
                r = (a*r + k*r2) / 255;
                g = (a*g + k*g2) / 255;
                b = (a*b + k*b2) / 255;
            }
        }
    }
}

void usage() {
    fprintf(stderr,
        "Shuffle the color channels of a PNG.\n\n"
        "Usage: swizzle -s [rgba01] -i in.png -o out.png\n\n"
        "  -s, --swizzle: exactly 4 channel identifiers (r/g/b/a) or constants (0/1)\n"
        "  -i, --infile: input file\n"
        "  -o, --outfile: output file\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    const char* outfile = NULL;
    const char* swizzle = NULL;
    int width = 0, height = 0, bpp = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = argv[++i];
        } else if (isFlag(s, "-s", "--swizzle")) {
            swizzle = argv[++i];
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }
    if (!infile || !outfile || !swizzle || strlen(swizzle) != 4) {
        usage();
    }

    fprintf(stderr, "Reading %s\n", infile);
    int w, h, comp;
    unsigned char* input = stbi_load(infile, &w, &h, &comp, 4);

    fprintf(stderr, "Fixing alpha...\n");
    fix_alpha(w, h, input);

    fprintf(stderr, "Swizzling...\n");
    unsigned char* output = (unsigned char*) malloc(w * h * 4);
    for (int i = 0; i < (w * h * 4); i += 4) {
        for (int j = 0; j < 4; ++j) {
            unsigned char value = 0;
            unsigned char r = input[i], g = input[i+1], b = input[i+2], a = input[i+3];
            switch (swizzle[j]) {
                case 'r': case 'R': value = r; break;
                case 'g': case 'G': value = g; break;
                case 'b': case 'B': value = b; break;
                case 'a': case 'A': value = a; break;
                case '0': value = 0; break;
                case '1': value = 255; break;
                default:
                    fprintf(stderr, "Unknown swizzle character: %c\n", swizzle[j]);
                    abort();
            }
            output[i + j] = value;
        }
    }

    fprintf(stderr, "Writing %s\n", outfile);
    stbi_write_png(outfile, w, h, 4, output, w * 4);
    return 0;
}
