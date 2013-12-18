#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

#ifdef AP_REPLACE_UI

@class AP_AlertView;

@protocol AP_AlertViewDelegate <NSObject>
- (void) alertView:(AP_AlertView*) alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface AP_AlertView : AP_View

- (id) initWithTitle:(NSString*)title message:(NSString*)message delegate:(id /*<UIAlertViewDelegate>*/)delegate cancelButtonTitle:(NSString*)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles, ...;

- (void) show;

- (NSString*) buttonTitleAtIndex:(NSInteger)buttonIndex;

@end

#else
typedef UIAlertView AP_AlertView;
#define AP_AlertViewDelegate UIAlertViewDelegate
#endif
