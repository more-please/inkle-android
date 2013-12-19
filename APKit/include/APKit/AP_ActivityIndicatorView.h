#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@interface AP_ActivityIndicatorView : AP_View

- (id) initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style;

@property UIActivityIndicatorViewStyle activityIndicatorViewStyle; // default is UIActivityIndicatorViewStyleWhite

- (void) startAnimating;
- (void) stopAnimating;
- (BOOL) isAnimating;

@end
