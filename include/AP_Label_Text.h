#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

@class AP_Font;

@interface AP_Label_Text : NSObject
- (AP_Label_Text*) initWithText:(NSString*)text;
- (CGFloat) floatValue;
- (CGSize) sizeWithFont:(AP_Font*)font constrainedToSize:(CGSize)size; // Uses NSLineBreakModeWordWrap
- (CGSize) sizeWithFont:(AP_Font*)font;
@end

#endif
