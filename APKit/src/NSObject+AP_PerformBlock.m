#import "NSObject+AP_PerformBlock.h"

@implementation NSObject(AP_PerformBlock)

- (void) performBlock:(void(^)())block
{
    block();
}

- (void) performBlock:(void(^)())block afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(performBlock:) withObject:block afterDelay:delay];
}

- (void) performBlock:(void(^)())block onThread:(NSThread*)thread waitUntilDone:(BOOL)waitUntilDone
{
    [self performSelector:@selector(performBlock:) onThread:thread withObject:block waitUntilDone:waitUntilDone];
}

@end