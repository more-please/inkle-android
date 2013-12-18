#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#ifdef AP_REPLACE_UI

@class AP_Font;

@interface AP_Label_Text : NSObject
- (AP_Label_Text*) initWithText:(NSString*)text;
- (CGSize) sizeWithFont:(AP_Font*)font constrainedToSize:(CGSize)size; // Uses NSLineBreakModeWordWrap
- (CGSize) sizeWithFont:(AP_Font*)font;

// NSString methods
- (CGFloat) floatValue;
- (NSUInteger)length;
- (unichar)characterAtIndex:(NSUInteger)index;
- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange;
- (BOOL)isEqualToString:(NSString *)aString;

// Bit of a hack... if we copy this object, return a real string!
// This lets us "cast" to NSString safely on both Android and iOS.
- (NSString*) copy;
@end

#endif
