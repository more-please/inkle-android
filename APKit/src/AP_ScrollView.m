#import "AP_ScrollView.h"

#import "AP_Check.h"

@implementation AP_ScrollView

- (id) init
{
    self = [super init];
    if (self) {
        _decelerationRate = UIScrollViewDecelerationRateNormal;
    }
    return self;
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
{
    if (animated) {
        AP_NOT_IMPLEMENTED;
    }
    _contentOffset = contentOffset;
}

@end
