#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@interface AP_ActivityIndicatorView : AP_View

- (id) initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style;

@property(nonatomic) UIActivityIndicatorViewStyle activityIndicatorViewStyle; // default is UIActivityIndicatorViewStyleWhite

@property(nonatomic,readonly) BOOL isAnimating;

- (void) startAnimating;
- (void) stopAnimating;

@end
