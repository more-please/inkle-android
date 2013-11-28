#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

@class AP_Font;

@interface AP_Label_Text : NSString
- (AP_Label_Text*) initWithText:(NSString*)text;
- (CGSize) sizeWithFont:(AP_Font*)font constrainedToSize:(CGSize)size; // Uses NSLineBreakModeWordWrap
- (CGSize) sizeWithFont:(AP_Font*)font;

// NSString methods
- (CGFloat) floatValue;
- (NSUInteger)length;
- (unichar)characterAtIndex:(NSUInteger)index;
- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange;
@end

#endif
