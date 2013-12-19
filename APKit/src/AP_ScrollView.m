#import "AP_ScrollView.h"

@implementation AP_ScrollView

- (id) init
{
    self = [super init];
    if (self) {
        _decelerationRate = UIScrollViewDecelerationRateNormal;
    }
    return self;
}

@end
