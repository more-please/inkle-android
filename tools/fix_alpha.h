#ifndef fix_alpha_h
#define fix_alpha_h

#include <vector>
#include <algorithm>

// Update the color of transparent pixels to be the average of nearby opaque pixels.
// This fixes mip-mapping artifacts such as color fringing.
void fix_alpha(int w, int h, unsigned char* data) {
    if (w > 1 && h > 1) {
        // Scale the image down by a factor of 2, summing each 2x2 pixel block.
        int w2 = (w+1) / 2;
        int h2 = (h+1) / 2;
        std::vector<unsigned char> data2;
        data2.resize(w2 * h2 * 4);
        for (int y2 = 0; y2 < h2; ++y2) {
            for (int x2 = 0; x2 < w2; ++x2) {
                int r = 0, g = 0, b = 0, a = 0;
                for (int yOffset = 0; yOffset < 2; ++yOffset) {
                    for (int xOffset = 0; xOffset < 2; ++xOffset) {
                        int x = std::min(2 * x2 + xOffset, w - 1);
                        int y = std::min(2 * y2 + yOffset, h - 1);
                        int alpha = data[4 * (x + y * w) + 3];
                        r += alpha * data[4 * (x + y * w)];
                        g += alpha * data[4 * (x + y * w) + 1];
                        b += alpha * data[4 * (x + y * w) + 2];
                        a += alpha;
                    }
                }
                if (a == 0) {
                    r = g = b = 127;
                    a = 1;
                }
                data2[4 * (x2 + y2 * w2)] = r / a;
                data2[4 * (x2 + y2 * w2) + 1] = g / a;
                data2[4 * (x2 + y2 * w2) + 2] = b / a;
                data2[4 * (x2 + y2 * w2) + 3] = a / 4;
            }
        }

        // Fix alpha in the reduced image.
        fix_alpha(w2, h2, &data2[0]);

        // Use the reduced image to fill in gaps in the full-size image.
        for (int y = 0; y < h; ++y) {
            for (int x = 0; x < w; ++x) {
                int x2 = x / 2;
                int y2 = y / 2;
                unsigned char r2 = data2[4 * (x2 + y2 * w2)];
                unsigned char g2 = data2[4 * (x2 + y2 * w2) + 1];
                unsigned char b2 = data2[4 * (x2 + y2 * w2) + 2];
                unsigned char& r = data[4 * (x + y * w)];
                unsigned char& g = data[4 * (x + y * w) + 1];
                unsigned char& b = data[4 * (x + y * w) + 2];
                unsigned char& a = data[4 * (x + y * w) + 3];
                int k = (255 - a);
                r = (a*r + k*r2) / 255;
                g = (a*g + k*g2) / 255;
                b = (a*b + k*b2) / 255;
            }
        }
    }
}

#endif
