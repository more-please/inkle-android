#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@interface AP_Touch : NSObject

- (CGPoint) locationInView:(AP_View*)view;

@property (nonatomic,assign) CGPoint windowPos;

+ (AP_Touch*) touchWithWindowPos:(CGPoint)pos;

@end

#ifdef ANDROID

// On Android, UITouch is a thin wrapper around an Android motion event.
// It holds a direct reference to an AP_Touch object.
@interface UITouch : NSObject

@property (nonatomic,strong) AP_Touch* android;
@property (nonatomic,assign) CGPoint location;

- (CGPoint)locationInView:(UIView*)view;

@end

#else

// On iOS, the AP_Touch is an associated object.
@interface UITouch(AP)
@property (nonatomic) AP_Touch* android;
@end

#endif
