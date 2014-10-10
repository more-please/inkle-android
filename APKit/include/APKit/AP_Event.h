#pragma once

#import <Foundation/Foundation.h>

@class AP_View;

@interface AP_Event : NSObject

@property(nonatomic,strong) NSSet* allTouches;
@property(nonatomic) NSTimeInterval timestamp;

- (NSSet*) touchesForView:(AP_View*) view;

//- (NSSet*) allTouches;
//- (NSSet*) touchesForWindow:(AP_Window*)window;
//- (NSSet*) touchesForGestureRecognizer:(UIGestureRecognizer *)gesture NS_AVAILABLE_IOS(3_2);

@end
