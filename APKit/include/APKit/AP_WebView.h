#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "AP_ScrollView.h"
#import "AP_View.h"

@class AP_WebView;

@protocol AP_WebViewDelegate <NSObject>
@optional
- (void)webViewDidStartLoad:(AP_WebView*)webView;
- (void)webViewDidFinishLoad:(AP_WebView*)webView;
@end

@interface AP_WebView : AP_View

@property(nonatomic,readonly,strong) AP_ScrollView* scrollView;
@property(nonatomic,weak) id<AP_WebViewDelegate> delegate;

- (void) loadHtmlResource:(NSString*)name;

@end
