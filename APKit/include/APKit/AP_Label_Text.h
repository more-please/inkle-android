#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@class AP_Font;

@interface AP_Label_Text : NSObject
- (AP_Label_Text*) initWithText:(NSString*)text;
- (CGSize) sizeWithFont:(UIFont*)font constrainedToSize:(CGSize)size; // Uses NSLineBreakModeWordWrap
- (CGSize) sizeWithFont:(UIFont*)font;

// NSString methods
- (float) floatValue;
- (NSUInteger)length;
- (unichar)characterAtIndex:(NSUInteger)index;
- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange;
- (BOOL)isEqualToString:(NSString *)aString;

// Bit of a hack... if we copy this object, return a real string!
// This lets us "cast" to NSString safely on both Android and iOS.
- (NSString*) copy;
@end
