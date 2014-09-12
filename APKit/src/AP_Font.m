#import "AP_Font.h"

#import "fontex.h"

#import "AP_Bundle.h"
#import "AP_Check.h"
#import "AP_Font_Data.h"
#import "AP_GLTexture.h"

@implementation AP_Font {
    CGFloat _size;
    AP_Font_Data* _font;
}

+ (AP_Font*) fontWithName:(NSString *)fontName size:(CGFloat)fontSize
{
    AP_Font* result = [[AP_Font alloc] init];
    result->_size = fontSize;
    result->_font = [AP_Font_Data fontDataNamed:fontName];
    AP_CHECK(result->_font, return nil);
    return result;
}

+ (AP_Font*) systemFontOfSize:(CGFloat)fontSize
{
    return [AP_Font fontWithName:@"Helvetica" size:fontSize];
}

+ (AP_Font*) boldSystemFontOfSize:(CGFloat)fontSize
{
    return [AP_Font fontWithName:@"Helvetica-Bold" size:fontSize];
}

+ (AP_Font*) italicSystemFontOfSize:(CGFloat)fontSize
{
    return [AP_Font fontWithName:@"Helvetica-Oblique" size:fontSize];
}

- (AP_Font *)fontWithSize:(CGFloat)fontSize
{
    AP_Font* result = [[AP_Font alloc] init];
    result->_size = fontSize;
    result->_font = _font;
    return result;
}

- (NSString*) fontName
{
    return _font.name;
}

- (CGFloat) pointSize
{
    return _size;
}

- (CGFloat) ascender
{
    return _font.header->ascent * (_size / _font.header->emSize);
}

- (CGFloat) descender
{
    return _font.header->descent * (_size / _font.header->emSize);
}

- (CGFloat) lineHeight
{
    return (_font.header->ascent - _font.header->descent + _font.header->leading) * (_size / _font.header->emSize);
}

- (CGFloat) leading
{
    return _font.header->leading * (_size / _font.header->emSize);
}

- (AP_Font_Run*) runForString:(NSString*)string
{
    size_t length = [string length];
    unichar* buffer = malloc(length * sizeof(unichar));
    AP_CHECK(buffer, return nil);
    [string getCharacters:buffer range:NSMakeRange(0, length)];
    AP_Font_Run* result = [self runForChars:buffer size:length];
    free(buffer);
    return result;
}

- (AP_Font_Run*) runForChars:(unichar*)chars size:(size_t)size
{
    unsigned char* buffer = malloc(size);
    AP_CHECK(buffer, return nil);

    unsigned char* dest = buffer;
    for (size_t i = 0; i < size; ++i) {
        unsigned char c = [_font glyphForChar:chars[i]];
        while ((i + 1) < size) {
            // Collapse ligatures.
            unsigned char c2 = [_font glyphForChar:chars[i+1]];
            unsigned char ligature;
            if (![_font ligatureForGlyph1:c glyph2:c2 ligature:&ligature index:i]) {
                break;
            }
            c = ligature;
            i++;
        }
        *dest++ = c;
    }
    AP_CHECK(dest <= buffer + size, abort());

    AP_Font_Run* result = [[AP_Font_Run alloc] initWithData:_font pointSize:_size glyphs:buffer length:(dest - buffer)];
    free(buffer);
    return result;
}

@end
