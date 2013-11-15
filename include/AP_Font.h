#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

// Wrapper for UIFont.
// Calls are delegated to a real UIFont object, but we adjust its size
// to match the screen density (Apportable doesn't handle sizes correctly).
@interface AP_Font : NSObject

+ (AP_Font*) fontWithName:(NSString *)fontName size:(CGFloat)fontSize;

//@property(nonatomic,readonly,retain) NSString *familyName;
@property(nonatomic,readonly,retain) NSString *fontName;
@property(nonatomic,readonly)        CGFloat   pointSize;
//@property(nonatomic,readonly)        CGFloat   ascender;
@property(nonatomic,readonly)        CGFloat   descender;
//@property(nonatomic,readonly)        CGFloat   capHeight;
//@property(nonatomic,readonly)        CGFloat   xHeight;
//@property(nonatomic,readonly)        CGFloat   lineHeight NS_AVAILABLE_IOS(4_0);
//@property(nonatomic,readonly)        CGFloat   leading;

// Create a new font that is identical to the current font except the specified size
- (AP_Font*) fontWithSize:(CGFloat)fontSize;

// Replacement for [NSString sizeWithFont:]
- (CGSize) sizeOfText:(NSString*)text;

// "Toll-free bridging" between AP_Font and UI_Font
@property(nonatomic,readonly) UIFont* realFont;
@property(nonatomic,readonly) AP_Font* fakeFont;

@end

@interface UIFont(AP)
@property(nonatomic,readonly) UIFont* realFont;
@property(nonatomic,readonly) AP_Font* fakeFont;
@end

#else
typedef UIFont AP_Font;
#endif
