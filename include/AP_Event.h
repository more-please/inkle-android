#import <Foundation/Foundation.h>

#ifdef AP_REPLACE_UI

@interface AP_Event : NSObject

@end

#else
typedef UIEvent AP_Event;
#endif
