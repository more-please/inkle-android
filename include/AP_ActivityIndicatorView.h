#import <Foundation/Foundation.h>

#import "AP_View.h"

#ifdef AP_REPLACE_UI

@interface AP_ActivityIndicatorView : AP_View

- (id) initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style;

@property UIActivityIndicatorViewStyle activityIndicatorViewStyle; // default is UIActivityIndicatorViewStyleWhite

- (void) startAnimating;
- (void) stopAnimating;
- (BOOL) isAnimating;

@end

#else
typedef UIActivityIndicatorView AP_ActivityIndicatorView;
#endif
