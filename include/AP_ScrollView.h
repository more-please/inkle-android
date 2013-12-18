#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

#ifdef AP_REPLACE_UI

#ifdef ANDROID
extern const CGFloat UIScrollViewDecelerationRateNormal;
extern const CGFloat UIScrollViewDecelerationRateFast;
#endif

@protocol AP_ScrollViewDelegate <NSObject>
@end

@interface AP_ScrollView : AP_View

@property CGPoint contentOffset; // default CGPointZero
@property CGSize contentSize; // default CGSizeZero

@property BOOL showsHorizontalScrollIndicator;
@property BOOL showsVerticalScrollIndicator;

@property(weak) id<AP_ScrollViewDelegate> delegate;

@property(getter=isPagingEnabled) BOOL pagingEnabled;// default NO. if YES, stop on multiples of view bounds

@property BOOL scrollsToTop; // default is YES.
@property BOOL bounces; // default YES. if YES, bounces past edge of content and back again

@property BOOL delaysContentTouches; // default is YES. if NO, we immediately call -touchesShouldBegin:withEvent:inContentView:
@property BOOL canCancelContentTouches; // default is YES. if NO, then once we start tracking, we don't try to drag if the touch moves

@property(getter=isDirectionalLockEnabled) BOOL directionalLockEnabled; // default NO.
@property CGFloat decelerationRate;

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;  // animate at constant velocity to new offset

@end

#else
typedef UIScrollView AP_ScrollView;
#define AP_ScrollViewDelegate UIScrollViewDelegate
#endif
