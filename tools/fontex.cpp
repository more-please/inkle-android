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
    { 10, 10 }, // Newline
    { 32, 126 }, // Basic ASCII
    { 192, 255 }, // Latin-1

    // Extra characters found in 80days.inkcontent
    { 163, 163 }, // Pound sign
    { 167, 167 }, // Section sign
    { 256, 257 }, // A/a with macron
    { 333, 333 }, // o with macron
    { 339, 339 }, // oe
    { 363, 363 }, // u with macron
    { 537, 537 }, // s with comma below

    // Misc extras
    { 0x00a9, 0x00a9 }, // (c)
    { 0x2018, 0x2019 }, // Single quotes
    { 0x201c, 0x201d }, // Double quotes
    { 0x2013, 0x2014 }, // en-dash, em-dash
    { 0x2026, 0x2026 }, // Ellipsis

    { 0, 0 }
};

// http://en.wikipedia.org/wiki/Typographic_ligature#Ligatures_in_Unicode_.28Latin-derived_alphabets.29
static const Ligature kLigatures[] = {
    { 'f', 'f', 0xfb00 },
    { 'f', 'i', 0xfb01 },
    { 'f', 'l', 0xfb02 },
    { 0xfb00, 'i', 0xfb03 }, // ffi
    { 0xfb00, 'l', 0xfb04 }, // ffl
//    { 'f', 't', 0xfb05 }, // I don't like this one
//    { 's', 't', 0xfb06 }, // This is considered 'quaint', don't overuse it!
    { 0, 0 }
};
// Good discussion here: http://english.stackexchange.com/questions/50660/when-should-i-not-use-a-ligature-in-english-typesetting

class Fontex {
public:
    long gap;
    long textureSize;

    explicit Fontex(const unsigned char* fontData)
        : _fontData(fontData)
        , _scale(0)
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
    }

    void layout() {
        sort(_glyphs.begin(), _glyphs.end(), Glyph::SizeCmp());

        // Find the appropriate scale.
        float maxScale = 1;
        float minScale = 0;
        while ((maxScale - minScale) > 1e-6) {
            float midScale = (minScale + maxScale) / 2;
            if (tryLayout(midScale) >= 0) {
                maxScale = midScale;
            } else {
                minScale = midScale;
            }
        }
        _scale = minScale;
        tryLayout(_scale);
    }

    void writeFont(const char* filename) {
        sort(_glyphs.begin(), _glyphs.end(), Glyph::CodepointCmp());
        sort(_ligatures.begin(), _ligatures.end());
        sort(_kerningPairs.begin(), _kerningPairs.end());

        fprintf(stderr, "Writing font: %s\n", filename);
        FILE* f = fopen(filename, "wb");

        int ascent, descent, leading;
        stbtt_GetFontVMetrics(&_font, &ascent, &descent, &leading);
        
        Header h;
        memset(&h, 0, sizeof(Header));
        strncpy(h.magic, "fontex02", 8);
        h.ascent = ascent;
        h.descent = descent;
        h.leading = leading;
        h.emSize = floor(0.5 + 1.0 / stbtt_ScaleForMappingEmToPixels(&_font, 1.0));
        h.numGlyphs = _glyphs.size();
        h.numLigatures = _ligatures.size();
        h.numKerningPairs = _kerningPairs.size();
        h.textureSize = textureSize;
        h.textureScale = _scale;

        fwrite(&h, sizeof(Header), 1, f);
        for (int i = 0; i < _glyphs.size(); ++i) {
            fwrite(&_glyphs[i], sizeof(Glyph), 1, f);
        }
        for (int i = 0; i < _ligatures.size(); ++i) {
            fwrite(&_ligatures[i], sizeof(Ligature), 1, f);
        }
        for (int i = 0; i < _kerningPairs.size(); ++i) {
            fwrite(&_kerningPairs[i], sizeof(KerningPair), 1, f);
        }
        fclose(f);
    }

    void writePng(const char* filename) {
        fprintf(stderr, "Writing PNG: %s\n", filename);
        unsigned char* data = (unsigned char*) calloc(textureSize, textureSize);
        render(_scale, data);
        stbi_write_png(filename, textureSize, textureSize, 1, data, textureSize);
        free(data);
    }

private:
    const unsigned char* _fontData;
    float _scale;
    stbtt_fontinfo _font;
    vector<Glyph> _glyphs;
    vector<Ligature> _ligatures;
    vector<KerningPair> _kerningPairs;

    void addCodepoint(int codepoint) {
        int metricsCodepoint = codepoint;
        if (codepoint == 10) {
            // Newline, use metrics for space.
            metricsCodepoint = 32;
        }
        if (!stbtt_FindGlyphIndex(&_font, metricsCodepoint)) {
            fprintf(stderr, "Warning: missing codepoint 0x%04x, skipping\n", codepoint);
            return;
        }
        int x0, y0, x1, y1, advance, bearing;
        stbtt_GetCodepointBitmapBox(&_font, metricsCodepoint, 1.0, 1.0, &x0, &y0, &x1, &y1);
        stbtt_GetCodepointHMetrics(&_font, metricsCodepoint, &advance, &bearing);
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
    long tryLayout(float scale) {
        long x = gap;
        long y = gap;
        long hMax = 0;
        for (vector<Glyph>::iterator i = _glyphs.begin(); i != _glyphs.end(); ++i) {
            Glyph& g = *i;
            long w = 1 + ceil(scale * g.width());
            long h = 1 + ceil(scale * g.height());
            if (x + w + gap > textureSize) {
                x = gap;
                y += hMax + gap;
                hMax = 0;
            }
            hMax = max(h, hMax);
            g.xTex = x;
            g.yTex = y;
            x += w + gap;
        }
        Glyph& g = _glyphs[_glyphs.size() - 1];
        x = g.xTex + gap + ceil(scale * g.width());
        y = g.yTex + gap + hMax;
//         fprintf(stderr, "Final glyph has coordinates: (%d,%d), (%d,%d)\n", g.xTex0, g.yTex0, g.xTex1, g.yTex1);
        long result = (x + textureSize * y) - (textureSize * textureSize);
//         fprintf(stderr, "Slop at scale %f is %ld\n", scale * 1e6, result);
        return result;
    }

    void render(float scale, unsigned char* data) {
//         fprintf(stderr, "Rendering at scale: %f\n", scale * 1e6);
        for (vector<Glyph>::iterator i = _glyphs.begin(); i != _glyphs.end(); ++i) {
            const Glyph& g = *i;
            long w = 1 + ceil(scale * g.width());
            long h = 1 + ceil(scale * g.height());
            unsigned char* ptr = data + (g.yTex * textureSize) + g.xTex;
//             fprintf(stderr, "Rendering codepoint 0x%04x at %d,%d (size %ld,%ld)\n", g.codepoint, g.xTex0, g.yTex0, w, h);
            if (w >= textureSize || h >= textureSize) {
                continue;
            }
            stbtt_MakeCodepointBitmap(&_font, ptr, w, h, textureSize, scale, scale, g.codepoint);
        }
    }
};

} // namespace fontex

void usage() {
    fprintf(stderr,
        "Generates a PNG image containing a font table.\n\n"
        "Usage: fontex font.ttf -p out.png -f out.apf [-s size] [-g gap]\n"
        "  -p, --png: output PNG file\n"
        "  -f, --font: output font data file\n"
        "  -s, --size: size in pixels (default 1024)\n"
        "  -g, --gap: minimum gap between characters (default 4)\n");
    fflush(stderr);
    exit(1);
}

bool isFlag(const char* s, const char* flag1, const char* flag2) {
    return strcmp(s, flag1) == 0 || strcmp(s, flag2) == 0;
}

int main(int argc, const char* argv[]) {
    const char* infile = NULL;
    const char* outpng = NULL;
    const char* outfont = NULL;
    int size = 1024;
    int gap = 4;
    for (int i = 1; i < argc; ++i) {
        const char* s = argv[i];
        if (isFlag(s, "-p", "--png")) {
            outpng = argv[++i];
        } else if (isFlag(s, "-f", "--font")) {
            outfont = argv[++i];
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

    static unsigned char buffer[1<<25];
    fread(buffer, 1, 1<<25, fopen(infile, "rb"));

    Fontex fontex(buffer);
    fontex.textureSize = size;
    fontex.gap = gap;
    fontex.layout();
    if (outpng) {
        fontex.writePng(outpng);
    }
    if (outfont) {
        fontex.writeFont(outfont);
    }
    return 0;
}
