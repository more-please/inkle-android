#include "fontex.h"

#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <algorithm>
#include <vector>

#include "stb_image_write.h"
#include "stb_truetype.h"

using namespace fontex;
using namespace std;

namespace fontex {

struct Range {
    int first;
    int last;
};

static const Range kRanges[] = {
    { 32, 126 }, // Basic ASCII
    { 192, 255 }, // Accented letters
    { 0x2018, 0x2019 }, // Single quotes
    { 0x201c, 0x201d }, // Double quotes
    { 0x2013, 0x2014 }, // en-dash, em-dash
    { 0, 0 }
};

// http://en.wikipedia.org/wiki/Typographic_ligature#Ligatures_in_Unicode_.28Latin-derived_alphabets.29
static const Ligature kLigatures[] = {
    { 'f', 'f', 0xfb00 },
    { 'f', 'i', 0xfb01 },
    { 'f', 'l', 0xfb02 },
    { 0xfb00, 'i', 0xfb03 },
    { 0xfb00, 'l', 0xfb04 },
    { 'f', 't', 0xfb05 },
    { 's', 't', 0xfb06 },
    { 0, 0 }
};

class Fontex {
public:
    long gap;
    long textureSize;

    explicit Fontex(const unsigned char* fontData)
        : _fontData(fontData)
        , gap(8)
        , textureSize(1024)
    {
        stbtt_InitFont(&_font, _fontData, 0);
        for (int i = 0; kRanges[i].first; ++i) {
            for (int j = kRanges[i].first; j <= kRanges[i].last; ++j) {
                addCodepoint(j);
            }
        }
        for (int i = 0; kLigatures[i].lhs; ++i) {
            maybeAddLigature(kLigatures[i]);
        }
        for (vector<Glyph>::iterator i = _glyphs.begin(); i != _glyphs.end(); ++i) {
            for (vector<Glyph>::iterator j = _glyphs.begin(); j != _glyphs.end(); ++j) {
                Glyph& g1 = *i;
                Glyph& g2 = *j;
                maybeKern(g1.codepoint, g2.codepoint);
            }
        }
        sort(_glyphs.begin(), _glyphs.end(), Glyph::SizeCmp());
    }

    void writePng(const char* filename) {
        // Find the appropriate scale.
        double maxScale = 1;
        double minScale = 0;
        while ((maxScale - minScale) > 1e-12) {
            double midScale = (minScale + maxScale) / 2;
            if (layout(midScale) >= 0) {
                maxScale = midScale;
            } else {
                minScale = midScale;
            }
        }

        unsigned char* data = (unsigned char*) calloc(textureSize, textureSize);
        render(minScale, data);
        fprintf(stderr, "Writing %s\n", filename);
        stbi_write_png(filename, textureSize, textureSize, 1, data, textureSize);
        free(data);
    }

private:
    const unsigned char* _fontData;
    stbtt_fontinfo _font;
    vector<Glyph> _glyphs;
    vector<Ligature> _ligatures;
    vector<KerningPair> _kerningPairs;

    void addCodepoint(int codepoint) {
        if (!stbtt_FindGlyphIndex(&_font, codepoint)) {
            fprintf(stderr, "Codepoint not found: %d\n", codepoint);
        }
        int x0, y0, x1, y1, advance, bearing;
        stbtt_GetCodepointBitmapBox(&_font, codepoint, 1.0, 1.0, &x0, &y0, &x1, &y1);
        stbtt_GetCodepointHMetrics(&_font, codepoint, &advance, &bearing);
        Glyph g;
        g.codepoint = codepoint;
        g.advance = advance;
        g.x0 = x0;
        g.x1 = x1;
        g.y0 = y0;
        g.y1 = y1;
        g.xTex = g.yTex = 0;
        _glyphs.push_back(g);
    }

    void maybeAddLigature(const Ligature& lig) {
        if (stbtt_FindGlyphIndex(&_font, lig.ligature)) {
            addCodepoint(lig.ligature);
            _ligatures.push_back(lig);
        }
    }

    void maybeKern(int lhs, int rhs) {
        int advance = stbtt_GetCodepointKernAdvance(&_font, lhs, rhs);
        if (advance) {
            KerningPair kp;
            kp.lhs = lhs;
            kp.rhs = rhs;
            kp.advance = advance;
            _kerningPairs.push_back(kp);
        }
    }

    // Return the amount by which we overflow the texture at this scale.
    long layout(double scale) {
        long w = 0, h = 0;
        long x = 1;
        long y = 1;
        for (vector<Glyph>::iterator i = _glyphs.begin(); i != _glyphs.end(); ++i) {
            Glyph& g = *i;
            w = ceil(scale * g.width());
            if (x + w + 1 > textureSize) {
                x = 1;
                y += h + gap;
            }
            h = ceil(scale * g.height());
            g.xTex = x;
            g.yTex = y;
            x += w + gap;
        }
        if (x + w + 1 > textureSize) {
            x = 1;
            y += h + gap;
        }
        y += h + 1;
        long result = (x + textureSize * y) - (textureSize * textureSize);
        return result;
    }

    void render(double scale, unsigned char* data) {
        for (vector<Glyph>::iterator i = _glyphs.begin(); i != _glyphs.end(); ++i) {
            const Glyph& g = *i;
            long w = ceil(scale * g.width());
            long h = ceil(scale * g.height());
            unsigned char* ptr = data + (g.yTex * textureSize) + g.xTex;
            stbtt_MakeCodepointBitmap(&_font, ptr, w, h, textureSize, scale, scale, g.codepoint);
        }
    }
};

} // namespace fontex

void usage() {
    fprintf(stderr,
        "Generates a PNG image containing a font table.\n\n"
        "Usage: fontex font.ttf -o pngfile [-s size] [-g gap]\n"
        "  -o, --outfile: output file (required)\n"
        "  -s, --size: size in pixels (default 1024)\n"
        "  -g, --gap: minimum gap between characters (default 8)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    const char* outfile = NULL;
    int size = 1024;
    int gap = 8;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-o", "--outfile")) {
            outfile = argv[++i];
        } else if (isFlag(s, "-s", "--size")) {
            size = atoi(argv[++i]);
        } else if (isFlag(s, "-g", "--gap")) {
            gap = atoi(argv[++i]);
        } else if (infile || s[0] == '-') {
            fprintf(stderr, "Bad argument '%s'\n\n", s);
            usage();
        } else {
            infile = s;
        }
    }
    if (!infile) {
        fprintf(stderr, "No input file specified\n\n");
        usage();
    }
    if (!outfile) {
        fprintf(stderr, "Missing --outfile\n\n");
        usage();
    }

    static unsigned char buffer[1<<25];
    fread(buffer, 1, 1<<25, fopen(infile, "rb"));

    Fontex fontex(buffer);
    fontex.textureSize = size;
    fontex.gap = gap;
    fontex.writePng(outfile);
    return 0;
}
