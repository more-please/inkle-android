#pragma once

#import <Foundation/Foundation.h>

#import "AP_GestureRecognizer.h"
#import "AP_ScrollView.h"
#import "AP_View.h"

@class AP_GLTexture;

@protocol AP_BookViewDelegate <NSObject>

- (AP_GLTexture*) textureForPage:(int)page leftSide:(BOOL)leftSide;

@end

@interface AP_BookView : AP_View <AP_GestureRecognizerDelegate>

@property(nonatomic) BOOL landscape;

- (instancetype) initWithPageCount:(int)pageCount delegate:(id<AP_BookViewDelegate>)delegate frame:(CGRect)frame;

- (int) currentPage;
- (void) setCurrentPage:(int)currentPage animated:(BOOL)animated;

@end
