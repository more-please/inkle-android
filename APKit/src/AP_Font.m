#import "AP_Font.h"

#import "fontex.h"

#import "AP_Bundle.h"
#import "AP_Check.h"
#import "AP_Font_Data.h"
#import "AP_GLTexture.h"

AP_Font_Data* fontDataNamed(NSString* name) {
    return [AP_Font_Data fontDataNamed:name];
}

@implementation UIFont (AP)

- (CGFloat) ascender
{
    return self.fontData.header->ascent * (self.pointSize / self.fontData.header->emSize);
}

- (CGFloat) descender
{
    return self.fontData.header->descent * (self.pointSize / self.fontData.header->emSize);
}

- (CGFloat) lineHeight
{
    return (self.fontData.header->ascent - self.fontData.header->descent + self.fontData.header->leading) * (self.pointSize / self.fontData.header->emSize);
}

- (CGFloat) leading
{
    return self.fontData.header->leading * (self.pointSize / self.fontData.header->emSize);
}

- (AP_Font_Run*) runForString:(NSString*)string kerning:(CGFloat)kerning
{
    size_t length = [string length];
    unichar* buffer = malloc(length * sizeof(unichar));
    AP_CHECK(buffer, return nil);
    [string getCharacters:buffer range:NSMakeRange(0, length)];
    AP_Font_Run* result = [self runForChars:buffer size:length kerning:kerning];
    free(buffer);
    return result;
}

- (AP_Font_Run*) runForChars:(unichar*)chars size:(size_t)size kerning:(CGFloat)kerning
{
    unsigned char* buffer = malloc(size);
    AP_CHECK(buffer, return nil);

    AP_Font_Data* f = self.fontData;

    unsigned char* dest = buffer;
    for (size_t i = 0; i < size; ++i) {
        unsigned char c = [f glyphForChar:chars[i]];
        while ((i + 1) < size) {
            // Collapse ligatures.
            unsigned char c2 = [f glyphForChar:chars[i+1]];
            unsigned char ligature;
            if (![f ligatureForGlyph1:c glyph2:c2 ligature:&ligature index:i]) {
                break;
            }
            c = ligature;
            i++;
        }
        *dest++ = c;
    }
    AP_CHECK(dest <= buffer + size, abort());

    AP_Font_Run* result = [[AP_Font_Run alloc] initWithData:f pointSize:self.pointSize kerning:kerning glyphs:buffer length:(dest - buffer)];
    free(buffer);
    return result;
}

@end
