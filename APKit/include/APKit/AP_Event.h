#pragma once

#import <Foundation/Foundation.h>

@interface AP_Event : NSObject

- (NSSet*) allTouches;
//- (NSSet*) touchesForWindow:(AP_Window*)window;
//- (NSSet*) touchesForView:(UIView *)view;
//- (NSSet*) touchesForGestureRecognizer:(UIGestureRecognizer *)gesture NS_AVAILABLE_IOS(3_2);

@end