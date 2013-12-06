#import <Foundation/Foundation.h>

@interface NSObject (AP_KeepAlive)
// Keep a reference to this object for the specified time.
// Useful in combination with AP_Cache, to prevent things being evicted too quickly.
- (void) keepAliveForTimeInterval:(NSTimeInterval)interval;
@end
