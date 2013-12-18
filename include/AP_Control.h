#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

#ifdef AP_REPLACE_UI

@interface AP_Control : AP_View

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@property(nonatomic,getter=isEnabled) BOOL enabled; // default is YES
@property(nonatomic,getter=isHighlighted) BOOL highlighted; // default is NO
@property(nonatomic,getter=isSelected) BOOL selected; // default is NO
@property(nonatomic,readonly,getter=isTracking) BOOL tracking;

@end

#else
typedef UIControl AP_Control;
#endif
