#pragma once

#include <stdlib.h>

static int clamp(int n, int lo, int hi) {
    if (n < lo) return lo;
    if (n > hi) return hi;
    return n;
}

static void blur3(float* data, int w, int h, const float kernel[3]) {
    float* temp = (float*) malloc(w * h * sizeof(float));

    // Horizontal, blur data -> temp
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            int x0 = clamp(x - 1, 0, w-1);
            int x1 = clamp(x + 0, 0, w-1);
            int x2 = clamp(x + 1, 0, w-1);

            float c0 = data[y*w + x0];
            float c1 = data[y*w + x1];
            float c2 = data[y*w + x2];
            temp[y*w + x] = c0 * kernel[0] + c1 * kernel[1] + c2 * kernel[2];
        }
    }

    // Vertical, blur temp -> data
    for (int y = 0; y < h; ++y) {
        int y0 = clamp(y - 1, 0, h-1);
        int y1 = clamp(y + 0, 0, h-1);
        int y2 = clamp(y + 1, 0, h-1);

        for (int x = 0; x < w; ++x) {
            float c0 = data[y0*w + x];
            float c1 = data[y1*w + x];
            float c2 = data[y2*w + x];
            data[y*w + x] = c0 * kernel[0] + c1 * kernel[1] + c2 * kernel[2];
        }
    }
}

static void blur5(float* data, int w, int h, const float kernel[5]) {
    float* temp = (float*) malloc(w * h * sizeof(float));

    // Horizontal, blur data -> temp
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            int x0 = clamp(x - 2, 0, w-1);
            int x1 = clamp(x - 1, 0, w-1);
            int x2 = clamp(x + 0, 0, w-1);
            int x3 = clamp(x + 1, 0, w-1);
            int x4 = clamp(x + 2, 0, w-1);

            float c0 = data[y*w + x0];
            float c1 = data[y*w + x1];
            float c2 = data[y*w + x2];
            float c3 = data[y*w + x3];
            float c4 = data[y*w + x4];
            temp[y*w + x] = c0 * kernel[0] + c1 * kernel[1] + c2 * kernel[2] + c3 * kernel[3] + c4 * kernel[4];
        }
    }

    // Vertical, blur temp -> data
    for (int y = 0; y < h; ++y) {
        int y0 = clamp(y - 1, 0, h-1);
        int y1 = clamp(y - 1, 0, h-1);
        int y2 = clamp(y + 0, 0, h-1);
        int y3 = clamp(y + 1, 0, h-1);
        int y4 = clamp(y + 2, 0, h-1);

        for (int x = 0; x < w; ++x) {
            float c0 = data[y0*w + x];
            float c1 = data[y1*w + x];
            float c2 = data[y2*w + x];
            float c3 = data[y3*w + x];
            float c4 = data[y4*w + x];
            data[y*w + x] = c0 * kernel[0] + c1 * kernel[1] + c2 * kernel[2] + c3 * kernel[3] + c4 * kernel[4];
        }
    }
}

static bool blur_rgba(uint8_t* dest, const uint8_t* src, int w, int h, const double* kernel, int kw, int kh) {
    bool done = true;
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const uint8_t* src_ptr = src + 4 * (y*w + x);
            uint8_t* dest_ptr = dest + 4 * (y*w + x);
            dest_ptr[3] = 255;

            if (src_ptr[3] > 0) {
                for (int comp = 0; comp < 3; ++comp) {
                    dest_ptr[comp] = src_ptr[comp];
                }
                continue;
            }

            double total[4] = { 0, 0, 0, 0 };
            for (int ky = 0; ky < kh; ++ky) {
                for (int kx = 0; kx < kw; ++kx) {
                    double k = kernel[ky*kw + kx];
                    int x0 = clamp(x + kx - kw/2, 0, w-1);
                    int y0 = clamp(y + ky - kh/2, 0, h-1);
                    const uint8_t* src_ptr = src + 4 * (y0*w + x0);
                    double alpha = src_ptr[3] / 255.0;
                    for (int comp = 0; comp < 3; ++comp) {
                        total[comp] += src_ptr[comp] * alpha;
                    }
                    total[3] += alpha;
                }
            }
            if (total[3] > 0) {
                for (int comp = 0; comp < 3; ++comp) {
                    dest_ptr[comp] = clamp(total[comp] / total[3], 0, 255);
                }
            } else {
                for (int comp = 0; comp < 3; ++comp) {
                    dest_ptr[comp] = 127;
                }
                dest_ptr[3] = 0;
                done = false;
            }
        }
    }
    return done;
}
