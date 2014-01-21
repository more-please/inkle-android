#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AP_Event;
@class AP_GestureRecognizer;
@class AP_Touch;
@class AP_View;

@protocol AP_GestureRecognizerDelegate <NSObject>
- (BOOL) gestureRecognizer:(AP_GestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(AP_GestureRecognizer*)other;
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
- (BOOL) shouldRecognizeSimultaneouslyWithGestureRecognizer:(AP_GestureRecognizer*)other;
- (void) wasAddedToView:(AP_View*)view;
- (void) fireWithState:(UIGestureRecognizerState)state;

@property(nonatomic,readonly,strong) NSMutableSet* touches;

- (void) addTouch:(AP_Touch*)touch withValue:(id)value;
- (id) valueForTouch:(AP_Touch*)touch;

@end

@interface AP_TapGestureRecognizer : AP_GestureRecognizer
@end

@interface AP_LongPressGestureRecognizer : AP_GestureRecognizer
@end

@interface AP_PinchGestureRecognizer : AP_GestureRecognizer
@property (nonatomic,readonly) CGFloat scale;               // scale relative to the touch points in screen coordinates
@end

@interface AP_PanGestureRecognizer : AP_GestureRecognizer
- (CGPoint) translationInView:(AP_View*)view;
@end
