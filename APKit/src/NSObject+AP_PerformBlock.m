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

@end
