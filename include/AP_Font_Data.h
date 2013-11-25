#import <Foundation/Foundation.h>

#import "AP_GLTexture.h"
#import "fontex.h"

@interface AP_Font_Data : NSObject

@property(nonatomic,readonly) NSString* name;
@property(nonatomic,readonly) const fontex_header_t* header;

+ (AP_Font_Data*) fontDataNamed:(NSString*)name;

- (unsigned char) glyphForChar:(unichar)c;
- (unichar) charForGlyph:(unsigned char)c;

- (const fontex_glyph_t*) dataForGlyph:(unsigned char)glyph;
- (int16_t) kerningForGlyph1:(unsigned char)c1 glyph2:(unsigned char)c2;
- (BOOL) ligatureForGlyph1:(unsigned char)c1 glyph2:(unsigned char)c2 ligature:(unsigned char*)ligature;

- (BOOL) isWordBreak:(unsigned char)c;
- (BOOL) isLineBreak:(unsigned char)c;

@end
