#pragma once

#include <stdint.h>

extern void separate_ink(
    uint8_t* rgbDest, // Must be width * height * 3 in size
    float* inkDest, // Must be width * height in size
    int threshold, // Maximum 8-bit luminosity of black pixels (16 is a good default)
    const uint8_t* rgbaSrc, // Must be width * height * 4 in size
    int width, int height);
