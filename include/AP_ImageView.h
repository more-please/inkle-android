#pragma once

#import <Foundation/Foundation.h>

#import "AP_Image.h"
#import "AP_View.h"

#ifdef AP_REPLACE_UI

@interface AP_ImageView : AP_View

- (AP_ImageView*) initWithImage:(AP_Image*)image;

@property AP_Image* image;

@property AP_Image* highlightedImage;
@property(getter=isHighlighted) BOOL highlighted;

@end

#else
typedef UIImageView AP_ImageView;
#endif
