#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

@class AP_View;

// Holds the timing and callback info for a single animation, which may affect multiple views.
// Doesn't correspond directly to any UIKit class.
@interface AP_Animation : NSObject

+ (NSArray*) animations;
+ (void) setMasterClock:(NSTimeInterval)time;

@property (nonatomic) NSString* tag;

- (id) initWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completion;

- (void) addView:(AP_View*)view;
- (void) removeView:(AP_View*)view;

// Called by AP_Window at the start of each GL frame.
- (void) update;

// Called by AP_View just before rendering.
- (CGFloat) progress; // In the range [0,1]

// Called by AP_View if its animation property is set.
// This can happen if another animation starts while this one is still running.
- (void) cancel;
- (void) finish;

@end

#endif