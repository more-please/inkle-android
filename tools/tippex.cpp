#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "separate_ink.h"

#include "stb_image.h"
#include "stb_image_write.h"

void tippex(const char* infile, int threshold, const char* fgfile, const char* bgfile)
{
    fprintf(stderr, "Loading %s\n", infile);
    int w, h, unused;
    uint8_t* data = stbi_load(infile, &w, &h, &unused, 3);

    uint8_t* rgbDest = NULL;
    uint8_t* inkDest = NULL;

    if (bgfile) {
        rgbDest = (uint8_t*) calloc(w * h, 3);
    }
    if (fgfile) {
        inkDest = (uint8_t*) calloc(w * h, 1);
    }
    
    separate_ink(rgbDest, inkDest, threshold, data, w, h);

    stbi_image_free(data);

    if (bgfile) {
        fprintf(stderr, "Writing %s\n", bgfile);
        stbi_write_png(bgfile, w, h, 3, rgbDest, w * 3);
        free(rgbDest);
    }

    if (fgfile) {
        fprintf(stderr, "Writing %s\n", fgfile);
        stbi_write_png(fgfile, w, h, 1, inkDest, w);
        free(inkDest);
    }
}

void usage() {
    fprintf(stderr,
        "Separate a cartoon-like image into foreground and background images.\n\n"
        "Usage: tippex [infile] -f fgfile -b bgfile\n"
        "  -f, --foreground output file for the foreground image (black lines)\n"
        "  -b, --background: output file for the background image (white and colour)\n"
        "  -t, --threshold: maximum 8-bit luminosity of black pixels (default: 16)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    const char* fgfile = NULL;
    const char* bgfile = NULL;
    int threshold = 16;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-f", "--foreground")) {
            fgfile = argv[++i];
        } else if (isFlag(s, "-b", "--background")) {
            bgfile = argv[++i];
        } else if (isFlag(s, "-t", "--threshold")) {
            threshold = atoi(argv[++i]);
        } else if (!infile) {
            infile = s;
        } else {
            fprintf(stderr, "Bad argument: %s\n\n", s);
            usage();
        }
    }
    if (!infile) {
        fprintf(stderr, "No input file specified\n\n");
        usage();
    }
    tippex(infile, threshold, fgfile, bgfile);
    return 0;
}
