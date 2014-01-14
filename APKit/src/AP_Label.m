#import "AP_Label.h"

#import <UIKit/UIKit.h>

#import "INKAttributedStringParagraphStyle.h"
#import "NSAttributedString+Attributes.h"

#import "AP_Check.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_Utils.h"

@implementation AP_Label {
    NSMutableAttributedString* _text;

    // Properties applied to non-attributed text.
    UIFont* _font;
    NSTextAlignment _alignment;
    UIColor* _textColor;
    UIColor* _shadowColor;
    CGSize _shadowOffset;

    CGFloat _layoutWidth;
    BOOL _atStartOfParagraph;
    BOOL _atStartOfLine;
    CGPoint _cursor;
    NSMutableArray* _formattedRuns;
    NSMutableArray* _currentLineRuns;
    INKAttributedStringParagraphStyle* _currentStyle;
    CGSize _formattedSize;
}

- (void) labelCommonInit
{
    self.userInteractionEnabled = NO;

    _text = [NSMutableAttributedString attributedStringWithString:@""];
    _font = [UIFont systemFontOfSize:17];
    _alignment = NSTextAlignmentNatural;
    _textColor = [UIColor blackColor];
    _shadowColor = [UIColor clearColor];
    _shadowOffset = CGSizeMake(0, -1);

    _numberOfLines = 1;
}

- (id) init
{
    self = [super init];
    if (self) {
        [self labelCommonInit];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self labelCommonInit];
    }
    return self;
}

- (NSAttributedString*) attributedText
{
    return [_text copy];
}

- (CGSize) sizeThatFits:(CGSize)size
{
    [self textLayoutWithWidth:size.width];
    return _formattedSize;
}

- (void) setAttributedText:(NSAttributedString *)attributedText
{
    AP_CHECK(attributedText, return);
    _text = [attributedText mutableCopy];
    [self setNeedsTextLayout];
}

- (AP_Label_Text*) text
{
    return [[AP_Label_Text alloc] initWithText:[_text string]];
}

- (void) setText:(NSString *)text
{
    if (!text) {
        // This often happens with textless buttons... Should the text be nil or empty?
        text = @"";
    }
    _text = [NSMutableAttributedString attributedStringWithString:text];
    [_text setFont:_font];
    [_text setTextColor:_textColor];
    [_text setTextAlignment:NSTextAlignmentToCTTextAlignment(_alignment)];
    [self setNeedsTextLayout];
}

- (UIFont*) font
{
    if (_text.length > 0) {
        return [_text attribute:kINKAttributedStringFontAttribute atIndex:0 effectiveRange:NULL];
    } else {
        return _font;
    }
}

- (void) setFont:(UIFont*)font
{
    _font = font;
    [_text setFont:font];
    [self setNeedsTextLayout];
}

- (UIColor*) textColor
{
    if (_text.length > 0) {
        return [_text attribute:kINKAttributedStringColorAttribute atIndex:0 effectiveRange:NULL];
    } else {
        return _textColor;
    }
}

- (void) setTextColor:(UIColor*)color
{
    _textColor = color;
    [_text setTextColor:color];
    [self setNeedsTextLayout];
}

- (void) setTextAlignment:(NSTextAlignment)alignment
{
    _alignment = alignment;
    [_text setTextAlignment:NSTextAlignmentToCTTextAlignment(alignment)];
    [self setNeedsTextLayout];
}

- (void) setShadowColor:(UIColor*)color
{
    _shadowColor = color;
}

- (void) setShadowOffset:(CGSize)offset
{
    AP_NOT_IMPLEMENTED;
}

- (void) setLineBreakMode:(NSLineBreakMode)mode
{
    // Do we really use anything other than word-wrapping?
    // To implement, blow away and recreate the font runs, I guess.
    AP_CHECK(mode == NSLineBreakByWordWrapping, return);
}

- (void) finishCurrentLine
{
    if (!_atStartOfLine) {
        _formattedSize.width = MAX(_formattedSize.width, _cursor.x - _currentStyle.tailIndent);

        CGPoint offset;
        
        // Calculate x offset based on line length and alignment.
        CGFloat xGap = (_layoutWidth + _currentStyle.tailIndent) - _cursor.x;
        switch (_currentStyle.alignment) {
            case kCTTextAlignmentRight:
                offset.x = xGap;
                break;

            case kCTTextAlignmentCenter:
                offset.x = xGap / 2;
                break;

            case kCTTextAlignmentJustified:
                AP_NOT_IMPLEMENTED;
                // fall through
            case kCTTextAlignmentLeft:
            case kCTTextAlignmentNatural:
            default:
                offset.x = 0;
                break;
        }

        // Calculate y adjustment based on maximum ascent and line height.
        CGFloat maxAscent = 0;
        CGFloat maxLineHeight = 0;
        for (AP_Font_Run* run in _currentLineRuns) {
            maxAscent = MAX(maxAscent, run.ascender);
            maxLineHeight = MAX(maxLineHeight, run.size.height);
        }
        offset.y = maxAscent;

        // Apply adjustments and mark the current line as formatted.
        for (AP_Font_Run* run in _currentLineRuns) {
            CGPoint p = run.origin;
            p.x += offset.x;
            p.y += offset.y;
            run.origin = p;
        }
        [_formattedRuns addObjectsFromArray:_currentLineRuns];
        _currentLineRuns = [NSMutableArray array];

        // Get ready for the next line.
        _cursor.x = 0;
        _cursor.y += maxLineHeight;
        _atStartOfLine = YES;

        _formattedSize.height = _cursor.y;
    }
}

- (void) setNeedsTextLayout
{
    _formattedRuns = nil;
}

- (void) textLayoutWithWidth:(CGFloat)width
{
    if (_formattedRuns && _layoutWidth == width) {
        return;
    }

    NSString* str = [_text string];

    INKAttributedStringParagraphStyle* defaultStyle = [INKAttributedStringParagraphStyle style];
    UIFont* defaultFont = [UIFont systemFontOfSize:17];
    UIColor* defaultColor = [UIColor blackColor];

    _layoutWidth = width;
    _formattedRuns = [NSMutableArray array];
    _currentLineRuns = [NSMutableArray array];
    _currentStyle = defaultStyle;
    _atStartOfParagraph = _atStartOfLine = YES;
    _cursor = CGPointZero;
    _formattedSize = CGSizeZero;

    [_text enumerateAttributesInRange:NSMakeRange(0, [_text length]) options:0 usingBlock:^(NSDictionary* attrs, NSRange range, BOOL* stop) {

        // Get the font, color and paragraph style.
        UIFont* font = [attrs objectForKey:kINKAttributedStringFontAttribute];
        if (!font) {
            font = defaultFont;
        }
        UIColor* color = [attrs objectForKey:kINKAttributedStringColorAttribute];
        if (!color) {
            color = defaultColor;
        }
        _currentStyle = [attrs objectForKey:kINKAttributedStringParagraphStyleAttribute];
        if (!_currentStyle) {
            _currentStyle = defaultStyle;
        }

        // Parse the characters.
        NSString* chars = [str substringWithRange:range];
        AP_Font_Run* run = [[AP_Font fontWithUIFont:font] runForString:chars];
        run.textColor = color;

        // Split at paragraph breaks, handle each paragraph separately.
        while (run.numChars > 0) {
            AP_Font_Run* nextParagraph;
            run = [run splitAtLineBreakLeaving:&nextParagraph];

            // Word-wrap as necessary.
            while (run.numChars > 0) {
                AP_Font_Run* nextLine;
                run = [run splitAtWidth:(_layoutWidth + _currentStyle.tailIndent - _cursor.x) leaving:&nextLine];
                if (run.numChars > 0) {
                    if (_atStartOfParagraph) {
                        _cursor.y += _currentStyle.paragraphSpacingBefore;
                        _cursor.x += _currentStyle.firstLineHeadIndent;
                    } else if (_atStartOfLine) {
                        _cursor.x += _currentStyle.headIndent;
                    }
                    run.origin = _cursor;
                    _cursor.x += run.size.width;
                    [_currentLineRuns addObject:run];
                } else if (_atStartOfLine) {
                    AP_LogError("Can't fit anything into the current line!");
                    // TODO: just split at the first place we can.
                    break;
                }

                _atStartOfLine = _atStartOfParagraph = NO;
                if (!nextLine) {
                    break;
                }
                [self finishCurrentLine];
                run = nextLine;
            }

            if (!nextParagraph) {
                break;
            }

            [self finishCurrentLine];

            _atStartOfParagraph = YES;
            _cursor.y += _currentStyle.paragraphSpacing;
            run = nextParagraph;
        }
    }];

    [self finishCurrentLine];
}

- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha
{
    [super renderWithBoundsToGL:boundsToGL alpha:alpha];

    CGRect bounds = self.bounds;
    [self textLayoutWithWidth:bounds.size.width];
    AP_CHECK(_formattedRuns, return);

    if (_centerVertically || _numberOfLines == 1) {
        CGFloat yGap = bounds.size.height - _formattedSize.height;
        boundsToGL = CGAffineTransformTranslate(boundsToGL, 0, yGap / 2);
    }

    // Render shadow, if any
    GLKVector4 shadowRgba = AP_ColorToVector(_shadowColor);
    shadowRgba.a *= alpha;
    if (shadowRgba.a > 0) {
        for (AP_Font_Run* run in _formattedRuns) {
            AP_CHECK(run, continue);
            CGAffineTransform boundsToShadow = CGAffineTransformTranslate(boundsToGL, _shadowOffset.width, _shadowOffset.height);
            [run renderWithBoundsToGL:boundsToShadow color:shadowRgba];
        }
    }

    // Render text
    for (AP_Font_Run* run in _formattedRuns) {
        AP_CHECK(run, continue);
        [run renderWithBoundsToGL:boundsToGL alpha:alpha];
    }
}

@end
