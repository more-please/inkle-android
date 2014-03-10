#import "AP_Font_Data.h"

#import "AP_Bundle.h"
#import "AP_Cache.h"
#import "AP_Check.h"

typedef struct KerningRHS {
    int16_t advance[256];
} KerningRHS;

typedef struct KerningLHS {
    KerningRHS* rhs[256];
} KerningLHS;

typedef struct LigatureRHS {
    unsigned char ligature[256];
} LigatureRHS;

typedef struct LigatureLHS {
    LigatureRHS* rhs[256];
} LigatureLHS;

@implementation AP_Font_Data {
    NSData* _data;
    const fontex_glyph_t* _glyphs;
    const fontex_ligature_t* _ligatures;
    const fontex_kerning_pair_t* _kerning;
    NSMutableDictionary* _charMap;
    unichar _glyphMap[256];
    LigatureLHS _ligatureMap;
    KerningLHS _kerningMap;
    NSMutableArray* _extraMaps;
    unsigned char _spaceGlyph;
    unsigned char _newlineGlyph;
}

+ (AP_Font_Data*) fontDataNamed:(NSString *)name
{
    static NSMutableDictionary* g_FontDataCache;
    if (!g_FontDataCache) {
        g_FontDataCache = [NSMutableDictionary dictionary];
    }
    AP_CHECK(g_FontDataCache, return nil);

    AP_Font_Data* result = [g_FontDataCache objectForKey:name];
    if (!result) {
        NSData* data = [AP_Bundle dataForResource:name ofType:@".font"];
        result = [[AP_Font_Data alloc] initWithName:name data:data];
        AP_CHECK(result, return nil);
        [g_FontDataCache setObject:result forKey:name];
    }
    return result;
}

static KerningRHS g_ZeroKerning;
static LigatureRHS g_ZeroLigature;

- (id) initWithName:(NSString*)name data:(NSData*)data
{
    AP_CHECK(name, return nil);
    AP_CHECK(data, return nil);
    self = [super init];
    if (self) {
        _name = name;
        _data = data;

        AP_CHECK([_data length] >= sizeof(fontex_header_t), return nil);
        _header = (const fontex_header_t*)[data bytes];
        AP_CHECK(0 == memcmp(_header->magic, "fontex02", 8), return nil);
        AP_CHECK(_header->numGlyphs < 256, return nil);

        size_t totalSize = sizeof(fontex_header_t)
            + _header->numGlyphs * sizeof(fontex_glyph_t)
            + _header->numLigatures * sizeof(fontex_ligature_t)
            + _header->numKerningPairs * sizeof(fontex_kerning_pair_t);
        AP_CHECK([_data length] >= totalSize, return nil);

        _glyphs = (const fontex_glyph_t*)(_header + 1);
        _ligatures = (const fontex_ligature_t*)(_glyphs + _header->numGlyphs);
        _kerning = (const fontex_kerning_pair_t*)(_ligatures + _header->numLigatures);

        for (int i = 0; i < 256; ++i) {
            g_ZeroLigature.ligature[i] = i;
            _glyphMap[i] = '?';
            _ligatureMap.rhs[i] = &g_ZeroLigature;
            _kerningMap.rhs[i] = &g_ZeroKerning;
        }
        _charMap = [NSMutableDictionary dictionary];
        for (int i = 0; i < _header->numGlyphs; ++i) {
            _glyphMap[i] = _glyphs[i].codepoint;
            NSNumber* key = [NSNumber numberWithUnsignedShort:_glyphMap[i]];
            NSNumber* value = [NSNumber numberWithUnsignedChar:i];
            [_charMap setObject:value forKey:key];
        }
        _extraMaps = [NSMutableArray array];
        for (int i = 0; i < _header->numLigatures; ++i) {
            const fontex_ligature_t* ligature = _ligatures + i;
            unsigned char g1 = [self glyphForChar:ligature->lhs];
            unsigned char g2 = [self glyphForChar:ligature->rhs];
            BOOL quaint = ligature->ligature >= 0xfb05;
            if (quaint) {
                // Quaint ligatures like "st" are too distracting, skip them.
                continue;
            }
            if (_ligatureMap.rhs[g1] == &g_ZeroLigature) {
                NSData* data = [NSData dataWithBytes:&g_ZeroLigature length:sizeof(LigatureRHS)];
                [_extraMaps addObject:data];
                _ligatureMap.rhs[g1] = (LigatureRHS*)[data bytes];
            }
            _ligatureMap.rhs[g1]->ligature[g2] = [self glyphForChar:ligature->ligature];
        }
        for (int i = 0; i < _header->numKerningPairs; ++i) {
            const fontex_kerning_pair_t* kerning = _kerning + i;
            unsigned char g1 = [self glyphForChar:kerning->lhs];
            unsigned char g2 = [self glyphForChar:kerning->rhs];
            if (_kerningMap.rhs[g1] == &g_ZeroKerning) {
                NSData* data = [NSData dataWithBytes:&g_ZeroKerning length:sizeof(KerningRHS)];
                [_extraMaps addObject:data];
                _kerningMap.rhs[g1] = (KerningRHS*)[data bytes];
            }
            _kerningMap.rhs[g1]->advance[g2] = kerning->advance;
        }
        _spaceGlyph = [self glyphForChar:' '];
        _newlineGlyph = [self glyphForChar:'\n'];

        NSString* textureName = [NSString stringWithFormat:@"%@.png", _name];
        _texture = [AP_GLTexture textureNamed:textureName limitSize:NO];
        AP_CHECK(_texture, return nil);
    }
    return self;
}

- (unsigned char) glyphForChar:(unichar)c
{
    NSNumber* key = [NSNumber numberWithUnsignedShort:c];
    NSNumber* result = [_charMap objectForKey:key];
    if (!result && c != '?') {
        return [self glyphForChar:'?'];
    }
    AP_CHECK(result, return 0);
    return [result unsignedCharValue];
}

- (unichar) charForGlyph:(unsigned char)c
{
    return _glyphMap[c];
}

- (const fontex_glyph_t*) dataForGlyph:(unsigned char)glyph
{
    AP_CHECK(glyph < _header->numGlyphs, return NULL);
    return _glyphs + glyph;
}

- (int16_t) kerningForGlyph1:(unsigned char)c1 glyph2:(unsigned char)c2
{
    return _kerningMap.rhs[c1]->advance[c2];
}

- (BOOL) ligatureForGlyph1:(unsigned char)c1 glyph2:(unsigned char)c2 ligature:(unsigned char*)ligature index:(int)index
{
    *ligature = _ligatureMap.rhs[c1]->ligature[c2];
    return (*ligature != c2);
}

- (BOOL) isLineBreak:(unsigned char)c
{
    return c == _newlineGlyph;
}

- (BOOL) isWordBreak:(unsigned char)c
{
    return c == _spaceGlyph;
}

@end
