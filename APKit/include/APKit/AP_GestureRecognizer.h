#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AP_Event;
@class AP_View;

@protocol AP_GestureRecognizerDelegate <NSObject>
@end

@interface AP_GestureRecognizer : NSObject

@property(nonatomic,weak) id<AP_GestureRecognizerDelegate> delegate;
@property(nonatomic,getter=isEnabled) BOOL enabled;
@property(nonatomic,readonly) UIGestureRecognizerState state;
@property(nonatomic,readonly,weak) AP_View* view;
@property(nonatomic) BOOL cancelsTouchesInView;

- (id) initWithTarget:(id)target action:(SEL)action;

- (CGPoint) locationInView:(AP_View*)view;
- (NSUInteger) numberOfTouches;

// Methods for subclasses
- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event;
- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event;
- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event;
- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event;
- (void) reset;

// Private stuff
- (void) wasAddedToView:(AP_View*)view;
- (void) fire;

@end

@interface AP_TapGestureRecognizer : AP_GestureRecognizer
@end

@interface AP_LongPressGestureRecognizer : AP_GestureRecognizer
@end

@interface AP_PinchGestureRecognizer : AP_GestureRecognizer
@property (nonatomic)          CGFloat scale;               // scale relative to the touch points in screen coordinates
@property (nonatomic,readonly) CGFloat velocity;            // velocity of the pinch in scale/second
@end

@interface AP_PanGestureRecognizer : AP_GestureRecognizer
- (CGPoint) velocityInView:(AP_View *)view;
- (CGPoint) translationInView:(AP_View*)view;
@end
