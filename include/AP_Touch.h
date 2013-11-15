#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

#import "AP_View.h"

@interface AP_Touch : NSObject

- (CGPoint) locationInView:(AP_View*)view;

@property (nonatomic) CGPoint windowPos;

+ (AP_Touch*) touchWithWindowPos:(CGPoint)pos;

@end

@interface UITouch(AP)

@property (nonatomic) AP_Touch* android;

@end

#else
typedef UITouch AP_Touch;
#endif
