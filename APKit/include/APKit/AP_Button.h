#pragma once

#import <Foundation/Foundation.h>

#import "AP_Control.h"
#import "AP_Image.h"
#import "AP_ImageView.h"
#import "AP_Label.h"

@interface AP_Button : AP_Control

+ (AP_Button*) buttonWithType:(UIButtonType)buttonType;

- (void) setTitle:(NSString*)title forState:(UIControlState)state;
- (void) setTitleColor:(UIColor*)color forState:(UIControlState)state;
- (void) setTitleShadowColor:(UIColor*)color forState:(UIControlState)state;
- (void) setImage:(AP_Image*)image forState:(UIControlState)state;
- (void) setBackgroundImage:(AP_Image*)image forState:(UIControlState)state;

- (NSString*)titleForState:(UIControlState)state;
- (UIColor*)titleColorForState:(UIControlState)state;
- (UIColor*)titleShadowColorForState:(UIControlState)state;
- (AP_Image*)imageForState:(UIControlState)state;
- (AP_Image*)backgroundImageForState:(UIControlState)state;

@property(nonatomic,readonly) AP_Label* titleLabel;
@property(nonatomic,readonly) AP_ImageView *imageView;

@property(nonatomic) UIEdgeInsets titleEdgeInsets; // default is UIEdgeInsetsZero
@property(nonatomic) UIEdgeInsets imageEdgeInsets; // default is UIEdgeInsetsZero
@property(nonatomic) BOOL showsTouchWhenHighlighted; // default is NO.
@property(nonatomic) BOOL adjustsImageWhenHighlighted; // default is YES.

@end
