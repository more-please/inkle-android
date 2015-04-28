#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ktx.h"
#include "rgba.h"

#include "read_entire_file.h"
#include "stb_image.h"

void usage() {
    fprintf(stderr,
        "Convert an image into an uncompressed texture in KTX format.\n\n"
        "Usage: ktx [-f rgba4] [-i in.png] [-o out.png]\n\n"
        "  -f, --format: format (currently only rgba4 is supported)\n"
        "  -i, --infile: input file (default is stdin)\n"
        "  -o, --outfile: output file (default is stdout)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    FILE* outfile = stdout;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-i", "--infile")) {
            infile = argv[++i];
        } else if (isFlag(s, "-o", "--outfile")) {
            outfile = fopen(argv[++i], "wb");
        } else if (isFlag(s, "-f", "--format")) {
            const char* format = argv[++i];
            if (strcmp(format, "rgba4") != 0) {
                fprintf(stderr, "Unsupported format: %s\n\n", format);
                usage();
            }
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }

    std::vector<unsigned char> file = read_entire_file(infile);

    int w, h, comp;
    unsigned char* rgba8 = stbi_load_from_memory(&file[0], file.size(), &w, &h, &comp, 4);

    std::vector<unsigned char> rgba4;
    rgba4.resize(w * h * 2);

    rgba4_from_rgba8(&rgba4[0], &rgba8[0], w, h);

    ktx_write_2d_uncompressed(
        outfile, KTX_UNSIGNED_SHORT_4_4_4_4, KTX_RGBA,
        w, h, &rgba4[0], rgba4.size());

    return 0;
}
