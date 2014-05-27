#include <stdlib.h>
#include <stdio.h>

#include "stb_image.h"

void bbox(const char* fname) {
    fprintf(stdout, "// %s\n", fname);
    int w, h, unused;
    unsigned char* data = stbi_load(fname, &w, &h, &unused, 4);
    int x0 = w, x1 = 0;
    int y0 = h, y1 = 0;
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            unsigned char alpha = data[4 * (x + y*w) + 3];
            if (alpha > 0) {
                if (x < x0) x0 = x;
                if (x > x1) x1 = x;
                if (y < y0) y0 = y;
                if (y > y1) y1 = y;
            }
        }
    }
    fprintf(stdout,
        "\"bbox\": {\n"
        "    \"x0\": %f,\n"
        "    \"x1\": %f,\n"
        "    \"y0\": %f,\n"
        "    \"y1\": %f\n"
        "},\n",
        x0 / double(w - 1),
        x1 / double(w - 1),
        y0 / double(h - 1),
        y1 / double(h - 1));
}


void usage() {
    fprintf(stderr,
        "Print the bounding box of the opaque parts of the given image.\n\n"
        "Usage: bbox infile\n");
    fflush(stderr);
    exit(1);
}

int main(int argc, const char* argv[]) {
    if (argc < 2) {
        usage();
    }
    for (int i = 1; i < argc; ++i) {
        bbox(argv[i]);
    }
    return 0;
}
