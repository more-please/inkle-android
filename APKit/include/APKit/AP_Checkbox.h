#pragma once

#import <Foundation/Foundation.h>

#import "AP_Control.h"
#import "AP_ImageView.h"
#import "AP_Label.h"

@interface AP_Checkbox : AP_Control

@property(nonatomic,readonly) AP_Label* label;
@property(nonatomic,readonly) AP_ImageView* icon;

@end
