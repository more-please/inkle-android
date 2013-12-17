#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef AP_REPLACE_UI

#import "AP_ScrollView.h"
#import "AP_View.h"

typedef enum UIWebViewNavigationType {
    UIWebViewNavigationTypeLinkClicked,
    UIWebViewNavigationTypeFormSubmitted,
    UIWebViewNavigationTypeBackForward,
    UIWebViewNavigationTypeReload,
    UIWebViewNavigationTypeFormResubmitted,
    UIWebViewNavigationTypeOther
}
UIWebViewNavigationType;

@class AP_WebView;

@protocol AP_WebViewDelegate <NSObject>
@end

@interface AP_WebView : AP_View
@property(nonatomic,readonly,retain) AP_ScrollView* scrollView;
@end

#else
typedef UIWebView AP_WebView;
#define AP_WebViewDelegate UIWebViewDelegate
#endif
