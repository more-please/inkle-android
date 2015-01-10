#import "UIWindow.h"

@implementation Real_UIWindow

- (id) init
{
    return [self initWithFrame:CGRectZero];
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) makeKeyAndVisible
{
    // Nothing
}

@end
