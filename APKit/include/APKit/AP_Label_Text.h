#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@class AP_Font;

@interface NSString (AP_Label_Text)

- (CGSize) sizeWithFont:(AP_Font*)font constrainedToSize:(CGSize)size; // Uses NSLineBreakModeWordWrap
- (CGSize) sizeWithFont:(AP_Font*)font;

@end
