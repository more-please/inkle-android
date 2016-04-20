#include "separate_ink.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <algorithm>
#include <vector>

#include "fix_alpha.h"

namespace {

const double GAMMA = 2.2;

double l2h(int i) {
    return pow(i / 255.0, GAMMA);
}

int h2l(double f) {
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

    Rgb(const uint8_t* rgb) : r(rgb[0]), g(rgb[1]), b(rgb[2]) {}

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

Rgb_f mix(Rgb_f a, Rgb_f b, double f) {
    Rgb_f result;
    result.r = (1 - f) * a.r + f * b.r;
    result.g = (1 - f) * a.g + f * b.g;
    result.b = (1 - f) * a.b + f * b.b;
    return result;
}

Rgb floor(Rgb_f r) {
    Rgb result(::floor(r.r), ::floor(r.g), ::floor(r.b));
    return result;
}

Rgb ceil(Rgb_f r) {
    Rgb result(::ceil(r.r), ::ceil(r.g), ::ceil(r.b));
    return result;
}

Rgb round(Rgb_f r) {
    Rgb result(::round(r.r), ::round(r.g), ::round(r.b));
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

    unsigned char* data() {
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
    unsigned char* _data;
    const int _w, _h;
};

} // namespace

using namespace std;

void separate_ink(
    uint8_t* rgbDest, // Must be width * height * 3 in size
    uint8_t* inkDest, // Must be width * height in size
    int threshold, // Maximum 8-bit luminosity of black pixels (16 is a good default)
    const uint8_t* rgbSrc, // Must be width * height * 3 in size
    int w, int h)
{
//     fprintf(stderr, "Zeroing out pixels with at least one neighbour within threshold\n");

    vector<uint8_t> bg;
    bg.resize(w*h*4);

    for (int i = 0; i < w*h; ++i) {
        for (int j = 0; j < 3; ++j) {
            bg[4*i + j] = rgbSrc[3*i + j];
        }
        bg[4*i + 3] = 255;
    }

    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            int i = y*w + x;
            if (Rgb(rgbSrc + i*3).isBelow(threshold)) {
                for (int _y = std::max(0, y-1); _y < std::min(h, y+2); ++_y) {
                    for (int _x = std::max(0, x-1); _x < std::min(w, x+2); ++_x) {
                        int _i = _y*w + _x;
                        bg[4*_i + 3] = 0;
                    }
                }
            }
        }
    }

//     fprintf(stderr, "Filling in zero pixels\n");
    fix_alpha(w, h, &bg[0]);

//     fprintf(stderr, "Extracting foreground pixels\n");

    vector<uint8_t> fg;
    fg.resize(w*h);

    for (int i = 0; i < w*h; ++i) {
        Rgb paper(&bg[4*i]);
        Rgb ink(rgbSrc + 3*i);
        double value = ink.gammaCorrectLuminosity() / paper.gammaCorrectLuminosity();
        fg[i] = h2l(value);
    }

    if (rgbDest) {
        for (int i = 0; i < w*h; ++i) {
            for (int j = 0; j < 3; ++j) {
                rgbDest[3*i + j] = bg[4*i + j];
            }
        }
    }

    if (inkDest) {
        memcpy(inkDest, &fg[0], w * h);
    }
}
