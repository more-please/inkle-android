#import <Foundation/Foundation.h>

@class AP_Font_Data;

@interface AP_Font_Run : NSObject

@property(nonatomic) CGPoint origin; // Default is (0,0)
@property(nonatomic,readonly) CGFloat ascender;
@property(nonatomic,readonly) CGFloat descender;
@property(nonatomic,readonly) CGSize size;
@property(nonatomic,readonly) size_t numChars;

- (AP_Font_Run*) initWithData:(AP_Font_Data*)data pointSize:(CGFloat)pointSize glyphs:(unsigned char*)glyphs length:(size_t)length;

- (AP_Font_Run*) splitAtWidth:(CGFloat)width leaving:(AP_Font_Run**)leftover;
- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL color:(GLKVector4)rgba;

@end
