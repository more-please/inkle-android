#ifndef fix_alpha_h
#define fix_alpha_h

// Sets all transparent pixels to pure black.
// This reduces mip-mapping artifacts such as color fringing.
void fix_alpha(int w, int h, unsigned char* data) {
    for (unsigned char* rgba = data; rgba < (data + w*h*4); rgba += 4) {
        if (rgba[3] == 0) {
            rgba[0] = rgba[1] = rgba[2] = 0;
        }
    }
}

#endif
