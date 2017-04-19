#import "AP_WebView.h"

#import <stdarg.h>

#import <libxml/HTMLparser.h>
#import <libxml/tree.h>

#import "AP_Bundle.h"
#import "AP_Check.h"
#import "AP_Image.h"
#import "AP_Label.h"
#import "AP_Window.h"

@implementation AP_WebView {
    AP_Label* _label;
    NSString* _indexHtml;
}

AP_BAN_EVIL_INIT;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        LIBXML_TEST_VERSION;

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _scrollView = [[AP_ScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [self addSubview:_scrollView];

        _label = [[AP_Label alloc] initWithFrame:self.bounds];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [_scrollView addSubview:_label];
    }
    return self;
}

- (void) dealloc
{
    xmlCleanupParser();
}

static BOOL isTags(xmlNode* n, const char* tags, ...) {
    if (n->type != XML_ELEMENT_NODE) {
        return NO;
    }

    const char* c = (const char*) n->name;
    BOOL found = (strcmp(c, tags) == 0);

    va_list args;
    va_start(args, tags);
    const char* tag = va_arg(args, const char*);
    while (tag) {
        if (strcmp(c, tag) == 0) {
            found = YES;
        }
        tag = va_arg(args, const char*);
    }
    va_end(args);

    return found;
}

static BOOL isTag(xmlNode* n, const char* tag) {
    if (n->type != XML_ELEMENT_NODE) {
        return NO;
    }
    if (strcmp((const char*) n->name, tag) == 0) {
        return YES;
    }
    return NO;
}

- (NSAttributedString*) parseText:(xmlNode*)n attrs:(NSDictionary*)attrs
{
    if (n->type == XML_TEXT_NODE) {
        NSString* content = [NSString stringWithUTF8String:(const char*)n->content];
        return [[NSMutableAttributedString alloc]
            initWithString:content
            attributes:attrs];
    }

#ifndef EIGHTY_DAYS
    // Sorcery! styles. TODO: extract this into game-specific code.
    if (isTag(n, "strong")) {
        AP_Font* font = [attrs objectForKey:NSFontAttributeName];
        font = [AP_Font fontWithName:@"Baskerville-Bold" size:font.pointSize];
        attrs = [attrs mutableCopy];
        [attrs setValue:font forKey:NSFontAttributeName];
    }

    if (isTag(n, "em")) {
        AP_Font* font = [attrs objectForKey:NSFontAttributeName];
        font = [AP_Font fontWithName:@"Baskerville-Italic" size:font.pointSize];
        attrs = [attrs mutableCopy];
        [attrs setValue:font forKey:NSFontAttributeName];
    }

    // Hack -- just so happens there's only one <span> in credits.css
    if (isTag(n, "span")) {
        AP_Font* font = [attrs objectForKey:NSFontAttributeName];
        font = [AP_Font fontWithName:@"Baskerville-Bold" size:font.pointSize * 1.2];
        attrs = [attrs mutableCopy];
        [attrs setValue:font forKey:NSFontAttributeName];
    }
#else
    // 80 Days styles
    if (isTags(n, "strong", "b", "em", "i", NULL)) {
        attrs = [attrs mutableCopy];
        [attrs setValue:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    }
#endif

    if (isTag(n, "a")) {
        // Hyperlinks in Holo blue: http://developer.android.com/design/style/color.html
        UIColor* color = [UIColor colorWithRed:0.2 green:0.71 blue:0.9 alpha:1];
        attrs = [attrs mutableCopy];
        [attrs setValue:color forKey:NSForegroundColorAttributeName];

        NSString* href = nil;
        for (xmlAttr* a = n->properties; a; a = a->next) {
            if (strcmp((const char*) a->name, "href") == 0) {
                href = [NSString stringWithUTF8String:(const char*)a->children->content];
            }
        }
        if (href) {
            [attrs setValue:href forKey:AP_UrlAttributeName];
        }
    }

    NSMutableAttributedString* buffer = [NSMutableAttributedString new];
    for (n = n->children; n; n = n->next) {
        NSAttributedString* s = [self parseText:n attrs:attrs];
        [buffer appendAttributedString:s];
    }
    return buffer;
}

#define WIDTH(x,y) [AP_Window widthForIPhone:x iPad:y]
#define HEIGHT(x,y) [AP_Window heightForIPhone:x iPad:y]
#define SIZE(x,y) MIN(WIDTH(x,y),HEIGHT(x,y))

- (NSAttributedString*) parseBody:(xmlNode*)n attrs:(NSDictionary*)attrs
{
    NSMutableAttributedString* buffer = [NSMutableAttributedString new];

    NSString* font = @"Baskerville";
    CGFloat size = SIZE(16,24);

    if (isTags(n, "a", "br", "p", "h1", "h2", "h3", "h4", NULL)) {

        CGFloat margin = [AP_Window iPhone:32 iPad:150 iPadLandscape:200];
        CGFloat kerning = 0;

        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.alignment = kCTTextAlignmentCenter;
        style.firstLineHeadIndent = margin;
        style.headIndent = margin;
        style.tailIndent = -margin;
        style.paragraphSpacingBefore = 4;

        UIColor* color = [attrs objectForKey:NSForegroundColorAttributeName];
        AP_TextTransform textTransform = nil;
#ifndef EIGHTY_DAYS
        // Sorcery! styles. TODO: extract this into game-specific code.
        if (isTags(n, "h1", "h2", NULL)) {
            font = @"Baskerville-Bold";
            style.paragraphSpacingBefore = SIZE(45, 90);
            style.paragraphSpacing = SIZE(30,60);
            size = SIZE(24, 32);
        } else if (isTag(n, "h3")) {
            // TODO: fancy letter-spacing
            font = @"Baskerville-Italic";
            style.paragraphSpacingBefore = [AP_Window scaleForIPhone:30 iPad:45];
            size = SIZE(19, 28);
        } else {
            style.paragraphSpacingBefore = 10;
            size = SIZE(16,24);
        }
#else
        // 80 Days styles.
        font = @"Futura-CondensedMedium";
        size = 18;

        if (isTag(n, "h1")) {
            style.paragraphSpacingBefore = 50;
            size = 72;
        } else if (isTag(n, "h3")) {
            style.paragraphSpacingBefore = 50;
            kerning = 2;
            font = @"Futura-Medium";
            size = 14;
            textTransform = ^(NSString* s) { return [s uppercaseString]; };
        } else if (isTag(n, "h4")) {
            color = [UIColor colorWithWhite:0xA0 / 255.0 alpha:1.0];
        } else if (isTag(n, "p")) {
            size = 12;
            font = @"Futura-Medium";
            color = [UIColor colorWithWhite:0x70 / 255.0 alpha:1.0];
        }

        // Font sizes seem really small, boost them
        size *= 1.25;
#endif

        attrs = @{
            NSForegroundColorAttributeName:color,
            NSFontAttributeName:[AP_Font fontWithName:font size:size],
            NSParagraphStyleAttributeName:style,
            NSKernAttributeName:@(kerning)
        };

        if (textTransform) {
            attrs = [attrs mutableCopy];
            [attrs setValue:textTransform forKey:AP_TextTransformAttributeName];
        }

        NSAttributedString* s = [self parseText:n attrs:attrs];
        [buffer appendAttributedString:s];

        NSAttributedString* end = [[NSAttributedString alloc] initWithString:@" \n" attributes:attrs];
        [buffer appendAttributedString:end];

    } else if (isTag(n, "img")) {
        NSString* src = nil;
        int width = 0;
        for (xmlAttr* a = n->properties; a; a = a->next) {
            if (strcmp((const char*) a->name, "src") == 0) {
                src = [NSString stringWithUTF8String:(const char*)a->children->content];
            }
            if (strcmp((const char*) a->name, "width") == 0) {
                width = atoi((const char*)a->children->content);
            }
        }

        AP_Image* image = nil;
        if (src) {
            // Strip off any @-suffix, we don't use those on Android.
            for (NSUInteger i = 0; i < src.length; ++i) {
                if ([src characterAtIndex:i] == '@') {
                    src = [src substringToIndex:i];
                    break;
                }
            }
            // The image path is relative to the HTML source file.
            NSString* dir = [_indexHtml stringByDeletingLastPathComponent];
            NSString* path = [dir stringByAppendingPathComponent:src];
            image = [AP_Image imageNamed:path];
        }
        if (image) {
            if (width) {
                image = [image imageWithWidth:width];
            }

            AP_Font* f = [AP_Font fontWithName:font size:size];
            NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
            style.alignment = NSTextAlignmentCenter;
            style.paragraphSpacing = SIZE(8,12);

            [buffer appendAttributedString:[[NSAttributedString alloc]
                initWithString:@"*"
                attributes:@{
                    NSFontAttributeName:f,
                    NSParagraphStyleAttributeName:style,
                    AP_ImageAttributeName:image,
                }
            ]];

            [buffer appendAttributedString:[[NSAttributedString alloc]
                initWithString:@"\n"
                attributes:@{
                    NSFontAttributeName:f,
                    NSParagraphStyleAttributeName:style,
                }
            ]];
        }
    } else {
        for (n = n->children; n; n = n->next) {
            NSAttributedString* s = [self parseBody:n attrs:attrs];
            [buffer appendAttributedString:s];
        }
    }
    return buffer;
}

- (NSAttributedString*) parseHtml:(xmlNode*)n attrs:(NSDictionary*)attrs
{
    NSMutableAttributedString* buffer = [NSMutableAttributedString new];
    for (n = n->children; n; n = n->next) {
        NSAttributedString* s;
        if (isTag(n, "body")) {
            s = [self parseBody:n attrs:attrs];
        } else {
            s = [self parseHtml:n attrs:attrs];
        }
        [buffer appendAttributedString:s];
    }
    return buffer;
}

- (void) loadHtmlResource:(NSString*)name
{
    if ([_delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_delegate webViewDidStartLoad:self];
    }

    _indexHtml = name;

    NSData* data = [AP_Bundle dataForResource:name ofType:nil];
    NSAssert(data, @"Couldn't find HTML resource: %@", name);
    xmlDoc* doc = htmlReadMemory((const char*)data.bytes, (int) data.length, name.UTF8String, NULL, 0);
    xmlNode* root = xmlDocGetRootElement(doc);

    NSAttributedString* text = [self parseHtml:root attrs:@{
        NSForegroundColorAttributeName:[UIColor whiteColor],
    }];

    xmlFreeDoc(doc);

    _label.attributedText = text;
    _label.centerVertically = NO;
    _label.numberOfLines = 0;

    if ([_delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_delegate webViewDidFinishLoad:self];
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    if (_label) {
#ifndef EIGHTY_DAYS
        CGFloat margin = [AP_Window scaleForIPhone:50 iPad:100];
#else
        CGFloat margin = [AP_Window scaleForIPhone:25 iPad:50];
#endif
        CGSize viewSize = _scrollView.frame.size;
        CGSize textSize = [_label sizeThatFits:viewSize];
        textSize.width = viewSize.width;

        _scrollView.contentSize = CGSizeMake(textSize.width, textSize.height + 2 * margin);
        _label.frame = CGRectMake(0, margin, textSize.width, textSize.height);
    }
}

@end
