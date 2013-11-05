#import <Foundation/Foundation.h>

#import "AP_Control.h"
#import "AP_Image.h"
#import "AP_Label.h"

#ifdef AP_REPLACE_UI

@interface AP_Button : AP_Control

+ (AP_Button*) buttonWithType:(UIButtonType)buttonType;

- (void) setTitle:(NSString*)title forState:(UIControlState)state;
- (void) setTitleColor:(UIColor*)color forState:(UIControlState)state;
- (void) setImage:(AP_Image*)image forState:(UIControlState)state;
- (void) setBackgroundImage:(AP_Image*)image forState:(UIControlState)state;

- (NSString*)titleForState:(UIControlState)state;
- (UIColor*)titleColorForState:(UIControlState)state;
- (AP_Image*)imageForState:(UIControlState)state;
- (AP_Image*)backgroundImageForState:(UIControlState)state;

@property(readonly) AP_Label* titleLabel;
@property UIEdgeInsets imageEdgeInsets; // default is UIEdgeInsetsZero
@property BOOL showsTouchWhenHighlighted; // default is NO.

@end

#else
typedef UIButton AP_Button;
#endif
