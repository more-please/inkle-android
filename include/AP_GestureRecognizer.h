#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef AP_REPLACE_UI

#ifdef ANDROID
typedef enum UIGestureRecognizerState {
    UIGestureRecognizerStatePossible,   // the recognizer has not yet recognized its gesture, but may be evaluating touch events. this is the default state
    
    UIGestureRecognizerStateBegan,      // the recognizer has received touches recognized as the gesture. the action method will be called at the next turn of the run loop
    UIGestureRecognizerStateChanged,    // the recognizer has received touches recognized as a change to the gesture. the action method will be called at the next turn of the run loop
    UIGestureRecognizerStateEnded,      // the recognizer has received touches recognized as the end of the gesture. the action method will be called at the next turn of the run loop and the recognizer will be reset to UIGestureRecognizerStatePossible
    UIGestureRecognizerStateCancelled,  // the recognizer has received touches resulting in the cancellation of the gesture. the action method will be called at the next turn of the run loop. the recognizer will be reset to UIGestureRecognizerStatePossible
    
    UIGestureRecognizerStateFailed,     // the recognizer has received a touch sequence that can not be recognized as the gesture. the action method will not be called and the recognizer will be reset to UIGestureRecognizerStatePossible
    
    // Discrete Gestures – gesture recognizers that recognize a discrete event but do not report changes (for example, a tap) do not transition through the Began and Changed states and can not fail or be cancelled
    UIGestureRecognizerStateRecognized = UIGestureRecognizerStateEnded // the recognizer has received touches recognized as the gesture. the action method will be called at the next turn of the run loop and the recognizer will be reset to UIGestureRecognizerStatePossible
}
UIGestureRecognizerState;
#endif

@class AP_GestureRecognizer;
@class AP_View;

@protocol AP_GestureRecognizerDelegate <NSObject>
@end

@interface AP_GestureRecognizer : NSObject

@property(nonatomic,assign) id<AP_GestureRecognizerDelegate> delegate;
@property(nonatomic,getter=isEnabled) BOOL enabled;
@property(nonatomic,readonly) UIGestureRecognizerState state;
@property(nonatomic,readonly) AP_View* view;
@property(nonatomic) BOOL cancelsTouchesInView;

- (id) initWithTarget:(id)target action:(SEL)action;

- (NSUInteger) numberOfTouches;

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
- (CGPoint)translationInView:(AP_View*)view;
@end

#else
typedef UIGestoreRecognizer AP_GestureRecognizer;
#define AP_GestureRecognizerDelegate UIGestureRecognizerDelegate
#endif
