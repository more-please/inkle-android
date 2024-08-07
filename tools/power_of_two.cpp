#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "read_entire_file.h"

#include "stb_image.h"
#include "stb_image_resize.h"
#include "stb_image_write.h"

void usage() {
    fprintf(stderr,
        "Scale the input up (or slightly down) so its dimensions are exact powers of two.\n\n"
        "Usage: power_of_two [-i in.png] [-o out.png]\n\n"
        "  -i, --infile: input file (default is stdin)\n"
        "  -o, --outfile: output file (default is stdout)\n"
        "  -m, --max: maximum size (default 4096)\n"
        "  -g, --gamma-correct-alpha: alpha channel is gamma-corrected\n"
        "  -p, --premultiplied-alpha: use premultiplied alpha\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    FILE* outfile = stdout;
    int maxsize = 4096, premultiplied = 0, gamma_correct = 0;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else if (isFlag(s, "-m", "--max")) {
            maxsize = atoi(argv[++i]);
        } else if (isFlag(s, "-p", "--premultiplied-alpha")) {
            premultiplied = 1;
        } else if (isFlag(s, "-g", "--gamma-correct-alpha")) {
            gamma_correct = 1;
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    std::vector<unsigned char> file = read_entire_file(infile);

    int w, h, comp;
    unsigned char* input = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 0);
    if (!input) {
        fprintf(stderr, "Error loading input image: %s\n", stbi_failure_reason());
        exit(1);
    }

    int w2 = 4, h2 = 4;
    double k = 1.25; // Allow images to be shrunk by this amount
    while (k * w2 < w && w2 < maxsize) {
        w2 *= 2;
    }
    while (k * h2 < h && h2 < maxsize) {
        h2 *= 2;
    }

    unsigned char* output;
    if (w2 == w && h2 == h) {
        output = input;
    } else {
        output = (unsigned char*) malloc(w2 * h2 * comp);

        int alpha_channel = STBIR_ALPHA_CHANNEL_NONE;
        if (comp == 2) alpha_channel = 1;
        if (comp == 4) alpha_channel = 3;

        int flags = 0;
        if (premultiplied) flags |= STBIR_FLAG_ALPHA_PREMULTIPLIED;
        if (gamma_correct) flags |= STBIR_FLAG_ALPHA_USES_COLORSPACE;

        stbir_resize_uint8_srgb(
            input, w, h, w * comp,
            output, w2, h2, w2 * comp, comp, alpha_channel,
            flags);
    }

    stbi_write_png_to_file(outfile, w2, h2, comp, output, w2 * comp);

    return 0;
}
