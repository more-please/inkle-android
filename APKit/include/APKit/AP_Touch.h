#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@interface AP_Touch : NSObject

- (CGPoint) locationInView:(AP_View*)view;

@property (nonatomic) CGPoint windowPos;

+ (AP_Touch*) touchWithWindowPos:(CGPoint)pos;

@end

#ifndef ANDROID
@interface UITouch(AP)
@property (nonatomic) AP_Touch* android;
@end
#endif
