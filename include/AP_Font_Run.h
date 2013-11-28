#import <Foundation/Foundation.h>

@class AP_Font_Data;

@interface AP_Font_Run : NSObject

@property(nonatomic,readonly) CGFloat ascender;
@property(nonatomic,readonly) CGFloat descender;
@property(nonatomic,readonly) CGFloat lineHeight;
@property(nonatomic,readonly) CGSize size;
@property(nonatomic,readonly) size_t numChars;
@property(nonatomic,readonly) int start;
@property(nonatomic,readonly) int end;

@property(nonatomic) CGPoint origin;
@property(nonatomic) UIColor* textColor; // default is nil (text draws black)
@property(nonatomic) UIColor* shadowColor; // default is nil (no shadow)
@property(nonatomic) CGSize shadowOffset; // default is CGSizeMake(0, -1) -- a top shadow

- (AP_Font_Run*) initWithData:(AP_Font_Data*)data pointSize:(CGFloat)pointSize glyphs:(unsigned char*)glyphs length:(size_t)length;

- (AP_Font_Run*) splitAtWidth:(CGFloat)width leaving:(AP_Font_Run**)leftover;
- (AP_Font_Run*) splitAtLineBreakLeaving:(AP_Font_Run**)leftover;

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha;

@end
