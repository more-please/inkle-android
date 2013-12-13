#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef AP_REPLACE_UI

@class AP_WebView;

@protocol AP_WebViewDelegate <NSObject>
@end

@interface AP_WebView : NSObject
@end

#else
typedef UIWebView AP_WebView;
#define AP_WebViewDelegate UIWebViewDelegate
#endif
