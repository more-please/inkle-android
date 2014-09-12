#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@class AP_AlertView;

@protocol AP_AlertViewDelegate <NSObject>
- (void) alertView:(AP_AlertView*) alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface AP_AlertView : AP_View

@property(nonatomic,weak) id<AP_AlertViewDelegate> delegate;

- (id) initWithTitle:(NSString*)title message:(NSString*)message delegate:(id<AP_AlertViewDelegate>)delegate cancelButtonTitle:(NSString*)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles, ...;

- (void) show;

- (NSString*) buttonTitleAtIndex:(NSInteger)buttonIndex;

@end
