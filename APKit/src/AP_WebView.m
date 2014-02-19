#import "AP_WebView.h"

#include <libxml/HTMLparser.h>
#include <libxml/tree.h>

#import "AP_Bundle.h"
#import "AP_Check.h"

@implementation AP_WebView

AP_BAN_EVIL_INIT;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        LIBXML_TEST_VERSION;

        _scrollView = [[AP_ScrollView alloc] initWithFrame:self.bounds];
        [self addSubview:_scrollView];
    }
    return self;
}

- (void) dealloc
{
    xmlCleanupParser();
}

static void print_element_names(xmlNode * a_node)
{
    xmlNode *cur_node = NULL;
    for (cur_node = a_node; cur_node; cur_node = cur_node->next) {
        NSLog(@"%s: %s\n", cur_node->name, cur_node->content);
        print_element_names(cur_node->children);
    }
}

- (void) loadHtmlResource:(NSString*)name
{
    if ([_delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_delegate webViewDidStartLoad:self];
    }

    NSData* data = [AP_Bundle dataForResource:name ofType:nil];
    xmlDoc* doc = htmlReadMemory((const char*)data.bytes, data.length, name.cString, NULL, 0);
    xmlNode* root = xmlDocGetRootElement(doc);
    print_element_names(root);
    xmlFreeDoc(doc);

    if ([_delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_delegate webViewDidFinishLoad:self];
    }
}

@end
