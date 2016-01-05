#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@interface AP_BookView : AP_View

- (instancetype) initWithPageTextures:(NSArray*)pageTextures frame:(CGRect)frame;

- (int) currentPage;
- (void) setCurrentPage:(int)currentPage animated:(BOOL)animated;

@end
