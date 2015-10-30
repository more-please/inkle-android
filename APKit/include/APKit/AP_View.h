#pragma once

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "AP_Animation.h"
#import "AP_AnimatedProperty.h"
#import "AP_GestureRecognizer.h"
#import "AP_Responder.h"

@class AP_Event;
@class AP_Layer;
@class AP_ViewController;
@class AP_Window;

@interface AP_View : AP_Responder

- (AP_View*) initWithFrame:(CGRect)frame;

- (void) addSubview:(AP_View*)view;
- (void) insertSubview:(AP_View*)view atIndex:(NSInteger)index;
- (void) insertSubview:(AP_View*)view belowSubview:(AP_View*)siblingSubview;
- (void) insertSubview:(AP_View*)view aboveSubview:(AP_View*)siblingSubview;
- (void) removeFromSuperview;

- (void) bringSubviewToFront:(AP_View*)view;
- (void) sendSubviewToBack:(AP_View*)view;

- (AP_View*) viewWithTag:(NSInteger)tag; // recursive search. includes self
@property (nonatomic) NSInteger tag; // default is 0

- (void) addGestureRecognizer:(AP_GestureRecognizer*)gestureRecognizer;
- (void) removeGestureRecognizer:(AP_GestureRecognizer*)gestureRecognizer;

- (CGSize) sizeThatFits:(CGSize)size;
- (void) sizeToFit;

- (void) setNeedsLayout;
- (void) layoutIfNeeded;
- (void) layoutSubviews;

- (void) setNeedsDisplay;
- (BOOL) takeNeedsDisplay;

- (AP_View*) hitTest:(CGPoint)point withEvent:(AP_Event*)event;
- (BOOL) pointInside:(CGPoint)point withEvent:(AP_Event*)event;

- (CGPoint)convertPoint:(CGPoint)point toView:(AP_View *)view;
- (CGPoint)convertPoint:(CGPoint)point fromView:(AP_View *)view;
- (CGRect)convertRect:(CGRect)rect toView:(AP_View *)view;
- (CGRect)convertRect:(CGRect)rect fromView:(AP_View *)view;

// As above, but uses the intermediate values during animations.
- (CGPoint)convertInFlightPoint:(CGPoint)point toView:(AP_View *)view;
- (CGPoint)convertInFlightPoint:(CGPoint)point fromView:(AP_View *)view;
- (CGRect)convertInFlightRect:(CGRect)rect toView:(AP_View *)view;
- (CGRect)convertInFlightRect:(CGRect)rect fromView:(AP_View *)view;

- (void)willRemoveSubview:(AP_View*)subview;
- (void)didAddSubview:(AP_View*)subview;

- (void)willMoveToSuperview:(AP_View*)newSuperview;
- (void)didMoveToSuperview;

- (void)willMoveToWindow:(AP_Window*)newWindow;
- (void)didMoveToWindow;

+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations;

+ (void)debugAnimationWithTag:(NSString*)tag;

+ (void)withoutAnimation:(void (^)(void))block;

@property(nonatomic,weak) AP_Window* window;
@property(nonatomic,readonly,weak) AP_View* superview;
@property(nonatomic,readonly) AP_Layer* layer;
@property(nonatomic,readonly,copy) NSMutableArray* subviews;
@property(nonatomic,readonly,copy) NSMutableArray* gestureRecognizers;

// Animated properties.
@property(nonatomic,readonly,strong) AP_AnimatedPoint* animatedBoundsOrigin;
@property(nonatomic,readonly,strong) AP_AnimatedSize* animatedBoundsSize;
@property(nonatomic,readonly,strong) AP_AnimatedPoint* animatedFrameCenter;
@property(nonatomic,readonly,strong) AP_AnimatedPoint* animatedAnchor;
@property(nonatomic,readonly,strong) AP_AnimatedTransform* animatedTransform;
@property(nonatomic,readonly,strong) AP_AnimatedVector4* animatedBackgroundColor;
@property(nonatomic,readonly,strong) AP_AnimatedFloat* animatedAlpha;

// Convenience accessor for all the animated properties as an array.
@property(nonatomic,readonly,strong) NSArray* animatedProperties;

// Called by [AP_AnimatedProperty initWithView:]
- (void) animatedPropertyWasAdded:(AP_AnimatedProperty*)prop;

// These delegate to the current value of the animated properties.
@property(nonatomic) CGRect bounds;
@property(nonatomic) CGRect frame;
@property(nonatomic) CGPoint center;
@property(nonatomic) CGAffineTransform transform;
@property(nonatomic,strong) UIColor* backgroundColor;
@property(nonatomic) CGFloat alpha;

@property(nonatomic,readonly) CGRect inFlightBounds;

@property(nonatomic) BOOL autoresizesSubviews; // default is YES.
@property(nonatomic) UIViewAutoresizing autoresizingMask;
@property(nonatomic) UIViewContentMode contentMode;

@property(nonatomic,getter=isOpaque) BOOL opaque; // Default is YES.
@property(nonatomic,getter=isHidden) BOOL hidden; // Default is NO.

@property(nonatomic) BOOL clipsToBounds; // Defaults to NO. Do we really need this?

@property(nonatomic,getter=isUserInteractionEnabled) BOOL userInteractionEnabled; // default is YES.

// Iain addition: allow hit test to return subviews outside my bounds.
@property(nonatomic) BOOL allowSubviewHitTestOutsideBounds;

// Prevent touches in this view from firing gesture recognizers in lower views.
@property(nonatomic) BOOL blockGestures;

// ----------------------------------------------------------------------
// Internal stuff

- (void) zOrderChanged;

@property(nonatomic,weak) AP_ViewController* viewDelegate;

@property(nonatomic,readonly) float timeSinceLastUpdate;

- (void) updateGL:(float)dt;
- (void) renderWithBoundsToGL:(CGAffineTransform)boundsToGL alpha:(CGFloat)alpha;
- (void) renderSelfAndChildrenWithFrameToGL:(CGAffineTransform)frameToGL alpha:(CGFloat)alpha;

// Traversing the view hierarchy
- (void) visitWithBlock:(void(^)(AP_View*))block;
- (void) visitControllersWithBlock:(void(^)(AP_ViewController*))block;

// Event dispatch. Visible subviews get first dibs, then self, then view controller.
- (BOOL) dispatchEvent:(EventHandlerBlock)handler;

@end
