#pragma once

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@class AP_Animation;
@class AP_View;

// Animatable properties of an AP_View.
@interface AP_AnimatedProperty : NSObject

@property(nonatomic,readonly,strong) NSString* name;
@property(nonatomic,readonly,weak) AP_View* view;
@property(nonatomic,strong) AP_Animation* animation;

- (instancetype) initWithName:(NSString*)name view:(AP_View*)view;

- (void) updateWithProgress:(CGFloat)progress; // Interpolate in-flight properties between previous and current.
- (void) cancelAnimation; // Stop the current animation, leaving properties in mid-flight.
- (void) finishAnimation; // Jump to the end of the current animation.

// Callbacks from AP_Animation.
- (void) animationWasCancelled;
- (void) animationWasFinished;

// Animation currently being set up by [AP_View animate...]
+ (AP_Animation*) currentAnimation;
+ (void) setCurrentAnimation:(AP_Animation*)animation;

// Internal stuff
- (BOOL) maybeJoinCurrentAnimation;

@end

@interface AP_AnimatedFloat : AP_AnimatedProperty
@property(nonatomic) CGFloat dest;
@property(nonatomic,readonly) CGFloat inFlight;
@end

@interface AP_AnimatedPoint : AP_AnimatedProperty
@property(nonatomic) CGPoint dest;
@property(nonatomic,readonly) CGPoint inFlight;
@end

@interface AP_AnimatedSize : AP_AnimatedProperty
@property(nonatomic) CGSize dest;
@property(nonatomic,readonly) CGSize inFlight;
@end

@interface AP_AnimatedVector4 : AP_AnimatedProperty
@property(nonatomic) GLKVector4 dest;
@property(nonatomic,readonly) GLKVector4 inFlight;
@end

@interface AP_AnimatedTransform : AP_AnimatedProperty
@property(nonatomic) CGAffineTransform dest;
@property(nonatomic,readonly) CGAffineTransform inFlight;
@end
