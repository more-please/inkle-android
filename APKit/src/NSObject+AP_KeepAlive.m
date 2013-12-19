#import "NSObject+AP_KeepAlive.h"

@implementation NSObject(AP_KeepAlive)

- (void) keepAliveForTimeInterval:(NSTimeInterval)interval
{
    [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(keepAliveExpired:) userInfo:self repeats:NO];
}

- (void) keepAliveExpired:(NSTimer*)timer
{
//    NSLog(@"Keep alive expired!");
}

@end
