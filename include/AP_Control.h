#import <Foundation/Foundation.h>

#import "AP_View.h"

#ifdef AP_REPLACE_UI

@interface AP_Control : AP_View

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@property(getter=isEnabled) BOOL enabled; // default is YES
@property(getter=isHighlighted) BOOL highlighted; // default is NO
@property(getter=isSelected) BOOL selected; // default is NO

@end

#else
typedef UIControl AP_Control;
#endif
