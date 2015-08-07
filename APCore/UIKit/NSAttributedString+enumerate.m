#import "NSAttributedString+enumerate.h"

#ifndef OSX

@implementation NSAttributedString (enumerate)

- (void)enumerateAttribute:(NSString*)attrName inRange:(NSRange)enumerationRange options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(id value, NSRange range, BOOL *stop))block
{
    assert(opts == 0); // Options not implemented yet!
    NSUInteger index = enumerationRange.location;
    BOOL shouldStop = NO;
    while (!shouldStop && index < (enumerationRange.location + enumerationRange.length)) {
        NSRange range;
        id value = [self attribute:attrName atIndex:index longestEffectiveRange:&range inRange:enumerationRange];
        block(value, range, &shouldStop);
        assert(range.length > 0);
        index += range.length;
    }
}

- (void)enumerateAttributesInRange:(NSRange)enumerationRange options:(NSAttributedStringEnumerationOptions)opts usingBlock:(void (^)(NSDictionary* attrs, NSRange range, BOOL *stop))block
{
    assert(opts == 0); // Options not implemented yet!
    NSUInteger index = enumerationRange.location;
    BOOL shouldStop = NO;
    while (!shouldStop && index < (enumerationRange.location + enumerationRange.length)) {
        NSRange range;
        NSDictionary* attrs = [self attributesAtIndex:index longestEffectiveRange:&range inRange:enumerationRange];
        block(attrs, range, &shouldStop);
        assert(range.length > 0);
        index += range.length;
    }
}

@end

#endif
