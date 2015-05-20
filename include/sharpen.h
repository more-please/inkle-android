#pragma once

#include <stdint.h>

#ifndef MAX
#define MAX(a,b) ((a)>(b)?(a):(b))
#endif

#ifndef MIN
#define MIN(a,b) ((a)<(b)?(a):(b))
#endif

// Compress the dynamic range of the given image by 3x, then extend the ranges of
// black and white pixels to enhance the sharpness of boundaries.

void sharpen(uint8_t* dest, const uint8_t* src, int width, int height, int comp) {
    const int end = width * height * comp;
    for (int i = 0; i < end; ++i) {
        const uint8_t center = src[i];
        const uint8_t left = src[MAX(0, i - comp)];
        const uint8_t right = src[MIN(end - 1, i + comp)];
        const uint8_t up = src[MAX(0, i - comp*width)];
        const uint8_t down = src[MIN(end - 1, i + comp*width)];
        if (center == 0) {
            dest[i] = MAX(MAX(left, right), MAX(up, down)) / 3;
        } else if (center == 255) {
            dest[i] = (2 * 255 + MIN(MIN(left, right), MIN(up, down)));
        } else {
            dest[i] = (255 + center) / 3;
        }
    }
}

void sharpen_float(float* dest, const float* src, int width, int height, int comp) {
    const int end = width * height * comp;
    for (int i = 0; i < end; ++i) {
        const float center = src[i];
        const float left = src[MAX(0, i - comp)];
        const float right = src[MIN(end - 1, i + comp)];
        const float up = src[MAX(0, i - comp*width)];
        const float down = src[MIN(end - 1, i + comp*width)];
        if (center == 0) {
            dest[i] = MAX(MAX(left, right), MAX(up, down)) / 3;
        } else if (center == 255) {
            dest[i] = (2 * 255 + MIN(MIN(left, right), MIN(up, down))) / 3;
        } else {
            dest[i] = (255 + center) / 3;
        }
    }
}
