#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@interface NSString (sizeWithFont)

- (CGSize) sizeWithFont:(UIFont*)font constrainedToSize:(CGSize)size; // Uses NSLineBreakModeWordWrap
- (CGSize) sizeWithFont:(UIFont*)font;

@end
