#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef AP_REPLACE_UI

@class AP_GestureRecognizer;

@protocol AP_GestureRecognizerDelegate <NSObject>
@end

@interface AP_GestureRecognizer : NSObject
@end

#else
typedef UIGestoreRecognizer AP_GestureRecognizer;
#define AP_GestureRecognizerDelegate UIGestureRecognizerDelegate
#endif
