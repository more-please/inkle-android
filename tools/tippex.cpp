#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "stb_image.h"
#include "stb_image_write.h"

const double GAMMA = 2.2;

static double l2h(int i) {
    return pow(i / 255.0, GAMMA);
}

static int h2l(double f) {
    int result = double(0.5 + 255 * pow(f, 1.0 / GAMMA));
    if (result < 0) result = 0;
    if (result > 255) result = 255;
    return result;
}

struct Rgb {
    unsigned char r;
    unsigned char g;
    unsigned char b;

    Rgb() : r(0), g(0), b(0) {}

    Rgb(int rr, int gg, int bb) {
        if (rr < 0) rr = 0;
        if (rr > 255) rr = 255;
        if (gg < 0) gg = 0;
        if (gg > 255) gg = 255;
        if (bb < 0) bb = 0;
        if (bb > 255) bb = 255;
        r = rr;
        g = gg;
        b = bb;
    }

    double luminosity() const {
        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    double gammaCorrectLuminosity() const {
        return 0.2126 * l2h(r) + 0.7152 * l2h(g) + 0.0722 * l2h(b);
    }

    bool isBelow(int threshold) const {
        // Maybe use luminosity here?
        return luminosity() <= threshold;
    }
};

struct Rgb_f {
    double r;
    double g;
    double b;

    Rgb_f() : r(0), g(0), b(0) {}
    Rgb_f(const Rgb& other) : r(other.r), g(other.g), b(other.b) {}

    const Rgb_f& operator+=(const Rgb_f& other) {
        r += other.r;
        g += other.g;
        b += other.b;
        return *this;
    }

    const Rgb_f& operator*=(double f) {
        r *= f;
        g *= f;
        b *= f;
        return *this;
    }

    const Rgb_f& operator/=(double f) {
        r /= f;
        g /= f;
        b /= f;
        return *this;
    }
};

static Rgb_f mix(Rgb_f a, Rgb_f b, double f) {
    Rgb_f result;
    result.r = (1 - f) * a.r + f * b.r;
    result.g = (1 - f) * a.g + f * b.g;
    result.b = (1 - f) * a.b + f * b.b;
    return result;
}

static Rgb floor(Rgb_f r) {
    Rgb result(floor(r.r), floor(r.g), floor(r.b));
    return result;
}

static Rgb ceil(Rgb_f r) {
    Rgb result(ceil(r.r), ceil(r.g), ceil(r.b));
    return result;
}

static Rgb round(Rgb_f r) {
    Rgb result(round(r.r), round(r.g), round(r.b));
    return result;
}

class Image {
public:
    Image(const Rgb* data, int w, int h) : _w(w), _h(h) {
        unsigned char* c = (unsigned char*) malloc(w * h * 3);
        memcpy((void*) c, data, w * h * 3);
        _data = c;
    }

    Image(int w, int h) : _w(w), _h(h) {
        _data = (unsigned char*) calloc(w * h, 3);
    }

    ~Image() {
        free((void*) _data);
    }

    const unsigned char* data() const {
        return _data;
    }

    Rgb& pixel(int x, int y) {
        if (x < 0) x = 0;
        if (x >= _w) x = _w - 1;
        if (y < 0) y = 0;
        if (y >= _h) y = _h - 1;
        return *((Rgb*)(_data + 3 * (y * _w + x)));
    }

    const Rgb& pixel(int x, int y) const {
        if (x < 0) x = 0;
        if (x >= _w) x = _w - 1;
        if (y < 0) y = 0;
        if (y >= _h) y = _h - 1;
        return *((Rgb*)(_data + 3 * (y * _w + x)));
    }

    Rgb_f avg(int x, int y, int w, int h) const {
        Rgb_f result;
        for (int yPos = y; yPos < y + h; ++yPos) {
            for (int xPos = x; xPos < x + w; ++xPos) {
                result += pixel(xPos, yPos);
            }
        }
        result /= (w * h);
        return result;
    }

    Rgb max(int x, int y, int w, int h) const {
        Rgb result;
        result.r = result.g = result.b = 0;
        for (int yPos = y; yPos < y + h; ++yPos) {
            for (int xPos = x; xPos < x + w; ++xPos) {
                const Rgb& p = pixel(xPos, yPos);
                if (p.r > result.r) result.r = p.r;
                if (p.g > result.g) result.g = p.g;
                if (p.b > result.b) result.b = p.b;
//                 if (p.luminosity() > result.luminosity()) {
//                     result = p;
//                 }
            }
        }
        return result;
    }

    Rgb min(int x, int y, int w, int h) const {
        Rgb result;
        result.r = result.g = result.b = 255;
        for (int yPos = y; yPos < y + h; ++yPos) {
            for (int xPos = x; xPos < x + w; ++xPos) {
                const Rgb& p = pixel(xPos, yPos);
                if (p.r < result.r) result.r = p.r;
                if (p.g < result.g) result.g = p.g;
                if (p.b < result.b) result.b = p.b;
//                 if (p.luminosity() < result.luminosity()) {
//                     result = p;
//                 }
            }
        }
        return result;
    }

    double sum(int x, int y, int size, const double* kernel) const {
        double result = 0;
        for (int j = 0; j < size; ++j) {
            for (int i = 0; i < size; ++i) {
                double weight = kernel[i] * kernel[j];
                const Rgb& p = pixel(x - size/2 + i, y - size/2 + j);
                result += weight * p.luminosity();
            }
        }
        return result;
    }

    Rgb nearestNonZeroPixels(int x, int y, int threshold) const {
        if (!pixel(x, y).isBelow(threshold)) {
            return pixel(x, y);
        }
        double weight = 0;
        Rgb_f rgb;
        for (int size = 3; ; size += 2) {
            for (int j = 0; j < size; ++j) {
                for (int i = 0; i < size; ++i) {
                    int xOffset = i - size/2;
                    int yOffset = j - size/2;
                    Rgb p = pixel(x + xOffset, y + yOffset);
                    if (!p.isBelow(threshold)) {
                        double w = 1.0 / sqrt(xOffset*xOffset + yOffset*yOffset);
                        Rgb_f fp = p;
                        fp *= w;
                        rgb += fp;
                        weight += w;
                    }
                }
            }
            if (weight > 0) {
                rgb /= weight;
                return round(rgb);
            }
        }
    }

private:
    const unsigned char* _data;
    const int _w, _h;
};

void tippex(const char* infile, int threshold, const char* fgfile, const char* bgfile) {

    fprintf(stderr, "Loading %s\n", infile);
    int w, h, unused;
    Rgb* data = (Rgb*) stbi_load(infile, &w, &h, &unused, 3);
    const Image input(data, w, h);
    stbi_image_free(data);

    fprintf(stderr, "Zeroing out pixels with at least one neighbour within threshold\n");
    Image scratch(w, h);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            if (input.min(x - 1, y - 1, 3, 3).isBelow(threshold)) {
                scratch.pixel(x, y) = Rgb();
            } else {
                scratch.pixel(x, y) = input.pixel(x, y);
            }
        }
    }

    fprintf(stderr, "Filling in zero pixels\n");
    Image bg(w, h);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            bg.pixel(x, y) = scratch.nearestNonZeroPixels(x, y, threshold);
        }
    }

    fprintf(stderr, "Extracting foreground pixels\n");
    unsigned char* fg = (unsigned char*) calloc(w, h);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            double paper = bg.pixel(x, y).gammaCorrectLuminosity();
            double ink = input.pixel(x, y).gammaCorrectLuminosity();
            double value = ink / paper;
            fg[x + w * y] = h2l(value);
        }
    }

    if (bgfile) {
        fprintf(stderr, "Writing %s\n", bgfile);
        stbi_write_png(bgfile, w, h, 3, bg.data(), w * 3);
    }

    if (fgfile) {
        fprintf(stderr, "Writing %s\n", fgfile);
        stbi_write_png(fgfile, w, h, 1, fg, w);
    }

    free(fg);
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
