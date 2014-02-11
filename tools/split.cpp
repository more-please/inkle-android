#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "stb_image.h"
#include "stb_image_write.h"

struct Rgb {
    unsigned char r;
    unsigned char g;
    unsigned char b;

    double luminosity() const {
        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
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
    Rgb result;
    result.r = floor(r.r);
    result.g = floor(r.g);
    result.b = floor(r.b);
    return result;
}

static Rgb ceil(Rgb_f r) {
    Rgb result;
    result.r = ceil(r.r);
    result.g = ceil(r.g);
    result.b = ceil(r.b);
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

private:
    const unsigned char* _data;
    const int _w, _h;
};

void split(const char* fgfile, const char* bgfile, const char* lofile, const char* hifile, const char* midfile) {
    fprintf(stderr, "Loading %s\n", fgfile);
    int fg_w, fg_h, unused;
    unsigned char* fg = stbi_load(fgfile, &fg_w, &fg_h, &unused, 1);

    fprintf(stderr, "Loading %s\n", bgfile);
    int w, h;
    Rgb* data = (Rgb*) stbi_load(bgfile, &w, &h, &unused, 3);
    const Image bg(data, w, h);
    stbi_image_free(data);

    assert(w == fg_w);
    assert(h == fg_h);

    fprintf(stderr, "Calculating 3x3 min and max\n");
    Image lo(w, h);
    Image hi(w, h);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            lo.pixel(x, y) = bg.min(x - 1, y - 1, 3, 3);
            hi.pixel(x, y) = bg.max(x - 1, y - 1, 3, 3);
//             Rgb_f avg = input.avg(x - 1, y - 1, 3, 3);
//             lo.pixel(x, y) = floor(mix(avg, lo.pixel(x, y), 0.75));
//             hi.pixel(x, y) = ceil(mix(avg, hi.pixel(x, y), 0.75));
        }
    }

    fprintf(stderr, "Calculating smoothed min/max deltas\n");
    const double kernel[3] = {0.2, 0.6, 0.2};
    unsigned char* mid = (unsigned char*) calloc(w, h);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            double lowerBound = lo.pixel(x, y).luminosity() - 1;
            double upperBound = hi.pixel(x, y).luminosity() + 1;
            double midpoint = bg.sum(x, y, 3, kernel);
            double shade = 255.0 * (midpoint - lowerBound) / (upperBound - lowerBound);

            int ink = fg[(y * w) + x];
            if (ink < 255) {
                shade = 0;
            }
            int c = floor((15 * ink + shade) / 16.0 + 0.5);
            if (c < 0) c = 0;
            if (c > 255) c = 255;
            mid[(y * w) + x] = c;
        }
    }

    if (lofile) {
        fprintf(stderr, "Writing %s\n", lofile);
        stbi_write_png(lofile, w, h, 3, lo.data(), w * 3);
    }
    if (hifile) {
        fprintf(stderr, "Writing %s\n", hifile);
        stbi_write_png(hifile, w, h, 3, hi.data(), w * 3);
    }
    if (midfile) {
        fprintf(stderr, "Writing %s\n", midfile);
        stbi_write_png(midfile, w, h, 1, mid, w);
    }
}

void usage() {
    fprintf(stderr,
        "Splits an image into three parts.\n\n"
        "Usage: split [infile] -l lofile -h hifile -m midfile\n"
        "  -f, --foreground: input file with the foreground image (black lines)\n"
        "  -b, --background: input file with the background image (white and colour)\n"
        "  -l, --lo: output file with the lowest value in each 3x3 block\n"
        "  -h, --hi: output file with the highest value in each 3x3 block\n"
        "  -m, --mid: output file encoding both lo/hi deltas and black lines\n\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* fgfile = NULL;
    const char* bgfile = NULL;
    const char* lofile = NULL;
    const char* hifile = NULL;
    const char* midfile = NULL;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-f", "--foreground")) {
            fgfile = argv[++i];
        } else if (isFlag(s, "-b", "--background")) {
            bgfile = argv[++i];
        } else if (isFlag(s, "-l", "--lo")) {
            lofile = argv[++i];
        } else if (isFlag(s, "-h", "--hi")) {
            hifile = argv[++i];
        } else if (isFlag(s, "-m", "--mid")) {
            midfile = argv[++i];
        } else {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        }
    }
    if (!fgfile) {
        fprintf(stderr, "No --foreground specified\n\n");
        usage();
    }
    if (!bgfile) {
        fprintf(stderr, "No --background specified\n\n");
        usage();
    }
    split(fgfile, bgfile, lofile, hifile, midfile);
    return 0;
}
