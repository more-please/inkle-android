#import "AP_Event.h"

@implementation AP_Event

- (NSSet*) touchesForView:(AP_View*)view
{
    // This is only used (in 80 Days) for ItemView, for drag tracking.
    // Just return all the touches, which will only cause minor problems
    // in the unlikely case of a multi-touch drag.
    return _allTouches;
}

@end
