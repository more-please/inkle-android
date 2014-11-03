#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "fix_alpha.h"

#include "stb_image.h"
#include "stb_image_write.h"

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
