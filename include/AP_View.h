#import <CoreGraphics/CoreGraphics.h>

#ifdef AP_REPLACE_UI

#import "AP_Layer.h"

@class AP_ViewController;
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

@property(nonatomic) AP_Window* window;
@property(nonatomic,readonly) AP_View* superview;
@property(nonatomic,readonly) AP_Layer* layer;
@property(nonatomic,readonly,copy) NSArray* subviews;

@property(nonatomic) CGRect bounds;
@property(nonatomic) CGRect frame;
@property(nonatomic) CGPoint center;
@property(nonatomic) CGAffineTransform transform;
@property(nonatomic) UIColor* backgroundColor;

@property(nonatomic) UIViewAutoresizing autoresizingMask;
@property(nonatomic) UIViewContentMode contentMode;
@property(nonatomic) CGFloat alpha;

@property(nonatomic,getter=isOpaque) BOOL opaque; // Default is YES.
@property(nonatomic,getter=isHidden) BOOL hidden; // Default is NO.

@property(nonatomic) BOOL clipsToBounds; // Defaults to NO. Do we really need this?

@property(nonatomic,getter=isUserInteractionEnabled) BOOL userInteractionEnabled; // default is YES.

@property(nonatomic) BOOL autoresizesSubviews; // default is YES. if set, subviews are adjusted according to their autoresizingMask if self.bounds changes

// Internal methods.
// The transform is from frame coordinates -> glViewport coordinates.
- (void) renderGL:(CGAffineTransform)transform;
- (void) renderSelfAndChildrenGL:(CGAffineTransform)transform;

@property(nonatomic,weak) AP_ViewController* viewDelegate;

@end

#else
typedef UIView AP_View;
#endif
