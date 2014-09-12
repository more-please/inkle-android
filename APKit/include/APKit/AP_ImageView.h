#pragma once

#import <Foundation/Foundation.h>

#import "AP_Image.h"
#import "AP_View.h"

@interface AP_ImageView : AP_View

- (instancetype) initWithImage:(AP_Image*)image;
- (instancetype) initWithImage:(AP_Image*)image highlightedImage:(AP_Image*)highlightedImage;

@property AP_Image* image;

@property AP_Image* highlightedImage;
@property(getter=isHighlighted) BOOL highlighted;

@end
