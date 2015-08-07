#pragma once

#import <Foundation/Foundation.h>

#import "UIDefines.h"

#ifndef OSX

// TODO - move this into SecondFoundation

@interface NSAttributedString (enumerate)

typedef NS_OPTIONS(NSUInteger, NSAttributedStringEnumerationOptions) {
  NSAttributedStringEnumerationReverse = (1UL << 1),
  NSAttributedStringEnumerationLongestEffectiveRangeNotRequired = (1UL << 20)
};

- (void) enumerateAttributesInRange:(NSRange)enumerationRange options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(NSDictionary* attrs, NSRange range, BOOL* stop))block;
- (void) enumerateAttribute:(NSString*) attrName inRange:(NSRange)enumerationRange options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(id value, NSRange range, BOOL* stop))block;

@end

#endif
