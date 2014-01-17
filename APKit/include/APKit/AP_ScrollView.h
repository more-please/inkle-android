#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@protocol AP_ScrollViewDelegate <NSObject>
@end

@interface AP_ScrollView : AP_View

@property(nonatomic) CGPoint contentOffset; // default CGPointZero
@property(nonatomic) CGSize contentSize; // default CGSizeZero

@property(nonatomic) BOOL showsHorizontalScrollIndicator;
@property(nonatomic) BOOL showsVerticalScrollIndicator;

@property(nonatomic,weak) id<AP_ScrollViewDelegate> delegate;

@property(nonatomic,getter=isPagingEnabled) BOOL pagingEnabled;// default NO. if YES, stop on multiples of view bounds

@property(nonatomic) BOOL scrollsToTop; // Scroll to the top on status bar tap. Currently ignored on Android.
@property(nonatomic) BOOL bounces; // default YES. if YES, bounces past edge of content and back again

@property(nonatomic) BOOL delaysContentTouches; // default is YES. if NO, we immediately call -touchesShouldBegin:withEvent:inContentView:
@property(nonatomic) BOOL canCancelContentTouches; // default is YES. if NO, then once we start tracking, we don't try to drag if the touch moves

@property(nonatomic,getter=isDirectionalLockEnabled) BOOL directionalLockEnabled; // default NO.
@property(nonatomic) CGFloat decelerationRate;

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;  // animate at constant velocity to new offset

@end
