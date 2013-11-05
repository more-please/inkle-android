#import <CoreGraphics/CoreGraphics.h>

#ifdef AP_REPLACE_UI

#import "AP_Layer.h"

@class AP_Window;

@interface AP_View : NSObject

- (AP_View*) initWithFrame:(CGRect)frame;

- (void) addSubview:(AP_View*)view;
- (void) insertSubview:(AP_View*)view atIndex:(NSInteger)index;
- (void) insertSubview:(AP_View*)view belowSubview:(AP_View*)siblingSubview;
- (void) insertSubview:(AP_View*)view aboveSubview:(AP_View*)siblingSubview;
- (void) removeFromSuperview;

- (void)bringSubviewToFront:(AP_View*)view;
- (void)sendSubviewToBack:(AP_View*)view;

- (BOOL) isDescendantOfView:(AP_View*)view; // returns YES for self.
- (AP_View*) viewWithTag:(NSInteger)tag; // recursive search. includes self
@property NSInteger tag; // default is 0

- (void) addGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer;

- (CGSize) sizeThatFits:(CGSize)size;
- (void) sizeToFit;

- (void) setNeedsDisplay;
- (void) setNeedsLayout;
- (void) layoutIfNeeded;
- (void) layoutSubviews;

// Should really be on AP_Responder. Maybe have AP_View subclass UIResponder?
- (BOOL) resignFirstResponder;
- (BOOL) isFirstResponder;

- (AP_View*) hitTest:(CGPoint)point withEvent:(UIEvent *)event;
- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event;

- (CGPoint)convertPoint:(CGPoint)point toView:(AP_View *)view;
- (CGPoint)convertPoint:(CGPoint)point fromView:(AP_View *)view;
- (CGRect)convertRect:(CGRect)rect toView:(AP_View *)view;
- (CGRect)convertRect:(CGRect)rect fromView:(AP_View *)view;

@property AP_Window* window;
@property (readonly) AP_View* superview;
@property (readonly) AP_Layer* layer;
@property (readonly,copy) NSArray* subviews;

@property CGRect bounds;
@property CGRect frame;
@property CGPoint center;
@property CGAffineTransform transform;
@property UIColor* backgroundColor;

@property UIViewAutoresizing autoresizingMask;
@property UIViewContentMode contentMode;
@property CGFloat alpha;

@property(getter=isOpaque) BOOL opaque; // Default is YES.
@property(getter=isHidden) BOOL hidden; // Default is NO.

@property BOOL clipsToBounds; // Defaults to NO. Do we really need this?

@property(getter=isUserInteractionEnabled) BOOL userInteractionEnabled; // default is YES.

@property BOOL autoresizesSubviews; // default is YES. if set, subviews are adjusted according to their autoresizingMask if self.bounds changes

// Internal methods.
// The transform is from frame coordinates -> glViewport coordinates.
- (void) renderGL:(CGAffineTransform)transform;
- (void) renderSelfAndChildrenGL:(CGAffineTransform)transform;

@end

#else
typedef UIView AP_View;
#endif
