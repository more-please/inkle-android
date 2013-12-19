#pragma once

#import <Foundation/Foundation.h>

#import "AP_View.h"

@class AP_TextField;

@protocol AP_TextFieldDelegate <NSObject>

@optional

- (BOOL)textFieldShouldBeginEditing:(AP_TextField *)textField;        // return NO to disallow editing.
- (void)textFieldDidBeginEditing:(AP_TextField *)textField;           // became first responder
- (BOOL)textFieldShouldEndEditing:(AP_TextField *)textField;          // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
- (void)textFieldDidEndEditing:(AP_TextField *)textField;             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called

- (BOOL)textField:(AP_TextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;   // return NO to not change text

- (BOOL)textFieldShouldClear:(AP_TextField *)textField;               // called when clear button pressed. return NO to ignore (no notifications)
- (BOOL)textFieldShouldReturn:(AP_TextField *)textField;              // called when 'return' key pressed. return NO to ignore.

@end

@interface AP_TextField : AP_View

@property NSString* text;

@end
