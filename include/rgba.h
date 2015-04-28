#pragma once

#include <stdint.h>

// Utilities for converting RGBA8 into various OpenGL texture formats.
// TODO: dithering

void rgba4_from_rgba8(uint8_t* dest, const uint8_t* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        uint8_t r4 = *src++ >> 4;
        uint8_t g4 = *src++ >> 4;
        uint8_t b4 = *src++ >> 4;
        uint8_t a4 = *src++ >> 4;
        // Little-endian shorts
        *dest++ = (b4 << 4) | a4;
        *dest++ = (r4 << 4) | g4;
    }
}

void rgb565_from_rgba8(uint8_t* dest, const uint8_t* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        uint8_t r5 = *src++ >> 3;
        uint8_t g6 = *src++ >> 2;
        uint8_t b5 = *src++ >> 3;
        uint8_t a_unused = *src++;
        // Little-endian shorts
        *dest++ = ((g6 & 7) << 5) | b5;
        *dest++ = (r5 << 3) | (g6 >> 3);
    }
}

void rgb5551_from_rgba8(uint8_t* dest, const uint8_t* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        uint8_t r5 = *src++ >> 3;
        uint8_t g5 = *src++ >> 3;
        uint8_t b5 = *src++ >> 3;
        uint8_t a1 = *src++ >> 7;
        // Little-endian shorts
        *dest++ = ((g5 & 3) << 6) | (b5 << 1) | a1;
        *dest++ = (r5 << 3) | (g5 >> 2);
    }
}
