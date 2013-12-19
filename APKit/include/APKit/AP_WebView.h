#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "AP_ScrollView.h"
#import "AP_View.h"

@class AP_WebView;

@protocol AP_WebViewDelegate <NSObject>
@end

@interface AP_WebView : AP_View
@property(nonatomic,readonly,retain) AP_ScrollView* scrollView;
@end
