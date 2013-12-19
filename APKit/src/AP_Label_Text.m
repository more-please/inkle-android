#import "AP_Label_Text.h"

#import "AP_Font.h"
#import "AP_Label.h"

@implementation AP_Label_Text {
    NSString* _text;
}

- (id) initWithText:(NSString*)text
{
    self = [super init];
    if (self) {
        _text = text;
    }
    return self;
}

- (CGSize) sizeWithFont:(UIFont*)font constrainedToSize:(CGSize)size
{
    AP_Label* label = [[AP_Label alloc] init];
    label.text = _text;
    label.font = font;
    return [label sizeThatFits:size];
}

- (CGSize) sizeWithFont:(UIFont*)font
{
    return [self sizeWithFont:font constrainedToSize:CGSizeMake(FLT_MAX, FLT_MAX)];
}

- (CGFloat) floatValue
{
    return [_text floatValue];
}

- (NSUInteger)length
{
    return [_text length];
}

- (unichar)characterAtIndex:(NSUInteger)index
{
    return [_text characterAtIndex:index];
}

- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange
{
    return [_text getCharacters:buffer range:aRange];
}

- (BOOL)isEqualToString:(NSString *)aString
{
    return [_text isEqualToString:aString];
}

- (NSString*) copy
{
    return _text;
}

@end
