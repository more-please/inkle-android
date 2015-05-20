#pragma once

#include <stdint.h>

// Utilities for converting RGBA8 into various OpenGL texture formats.
// TODO: dithering

void rgba4_from_rgba(uint8_t* dest, const float* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        uint8_t r4 = int(*src++) >> 4;
        uint8_t g4 = int(*src++) >> 4;
        uint8_t b4 = int(*src++) >> 4;
        uint8_t a4 = int(*src++) >> 4;
        // Little-endian shorts
        *dest++ = (b4 << 4) | a4;
        *dest++ = (r4 << 4) | g4;
    }
}

void rgb565_from_rgba(uint8_t* dest, const float* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        uint8_t r5 = int(*src++) >> 3;
        uint8_t g6 = int(*src++) >> 2;
        uint8_t b5 = int(*src++) >> 3;
        uint8_t a_unused = int(*src++);
        // Little-endian shorts
        *dest++ = ((g6 & 7) << 5) | b5;
        *dest++ = (r5 << 3) | (g6 >> 3);
    }
}

void rgba5551_from_rgba(uint8_t* dest, const float* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        uint8_t r5 = int(*src++) >> 3;
        uint8_t g5 = int(*src++) >> 3;
        uint8_t b5 = int(*src++) >> 3;
        uint8_t a1 = int(*src++) >> 7;
        // Little-endian shorts
        *dest++ = ((g5 & 3) << 6) | (b5 << 1) | a1;
        *dest++ = (r5 << 3) | (g5 >> 2);
    }
}

void rgba8_from_rgba(uint8_t* dest, const float* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        *dest++ = int(*src++);
        *dest++ = int(*src++);
        *dest++ = int(*src++);
        *dest++ = int(*src++);
    }
}

void rgb8_from_rgba(uint8_t* dest, const float* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        *dest++ = int(*src++);
        *dest++ = int(*src++);
        *dest++ = int(*src++);
        ++src; // alpha
    }
}

void la8_from_rgba(uint8_t* dest, const float* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        *dest++ = int(*src++);
        ++src; // green
        ++src; // blue
        *dest++ = int(*src++);
    }
}

void l8_from_rgba(uint8_t* dest, const float* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        *dest++ = int(*src++);
        ++src; // green
        ++src; // blue
        ++src; // alpha
    }
}

void a8_from_rgba(uint8_t* dest, const float* src, int width, int height) {
    for (int i = 0; i < width * height; ++i) {
        ++src; // red
        ++src; // green
        ++src; // blue
        *dest++ = int(*src++);
    }
}
