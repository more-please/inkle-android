#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AP_Event;
@class AP_GestureRecognizer;
@class AP_Touch;
@class AP_View;

@protocol AP_GestureRecognizerDelegate <NSObject>
@optional
- (BOOL) gestureRecognizer:(AP_GestureRecognizer*)recognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(AP_GestureRecognizer*)other;
@end

@interface AP_GestureRecognizer : NSObject

// Android addition -- it's sometimes useful to tweak this.
@property(nonatomic) CGFloat maxTapDistance; // Default is 10

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

- (void) addTouch:(AP_Touch*)touch;
- (void) addTouch:(AP_Touch*)touch withValue:(id)value;
- (id) valueForTouch:(AP_Touch*)touch;

@end

@interface AP_TapGestureRecognizer : AP_GestureRecognizer
@property (nonatomic) int numberOfTapsRequired;       // Default is 1. The number of taps required to match
@end

@interface AP_LongPressGestureRecognizer : AP_GestureRecognizer
@end

@interface AP_PinchGestureRecognizer : AP_GestureRecognizer
@property (nonatomic,readonly) CGFloat scale;               // scale relative to the touch points in screen coordinates
@property (nonatomic,readonly) CGFloat velocity;            // velocity of the pinch in scale/second
@end

@interface AP_PanGestureRecognizer : AP_GestureRecognizer
- (CGPoint) translationInView:(AP_View*)view;
- (CGPoint) velocityInView:(AP_View*)view;

// Iain's additions, used to make AP_ScrollView behave approximately right...
@property(nonatomic) BOOL preventHorizontalMovement;
@property(nonatomic) BOOL preventVerticalMovement;
@end
