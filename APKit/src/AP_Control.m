#import "AP_Control.h"

#import "AP_Touch.h"

@interface AP_Control_Action : NSObject 
@property (nonatomic,weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic) UIControlEvents events;
@end

@implementation AP_Control_Action
@end

@implementation AP_Control {
    AP_Touch* _touch;
    NSMutableArray* _actions;
}

//@property(nonatomic,getter=isEnabled) BOOL enabled; // default is YES
//@property(nonatomic,getter=isHighlighted) BOOL highlighted; // default is NO
//@property(nonatomic,getter=isSelected) BOOL selected; // default is NO
//@property(nonatomic,readonly,getter=isTracking) BOOL tracking

- (id) init
{
    return [self initWithFrame:CGRectMake(0, 0, 0, 0)];
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _enabled = YES;
        _actions = [NSMutableArray array];
    }
    return self;
}

- (void) addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    AP_Control_Action* ack = [[AP_Control_Action alloc] init];
    ack.target = target;
    ack.action = action;
    ack.events = controlEvents;
    [_actions addObject:ack];
}

- (void) dispatchEvent:(UIControlEvents)event
{
    if (!self.isUserInteractionEnabled) {
        return;
    }
    if (self.animation && !(self.animation.options & UIViewAnimationOptionAllowUserInteraction)) {
        return;
    }
    for (AP_Control_Action* ack in _actions) {
        if (ack.events & event) {
            id target = ack.target;
            if (target) {
                IMP imp = [target methodForSelector:ack.action];
                void (*func)(id, SEL, AP_Control*) = (void *)imp;
                func(target, ack.action, self);
            }
        }
    }
}

- (BOOL) isTracking
{
    return (_touch != nil);
}

- (void) touchesBegan:(NSSet*)touches withEvent:(AP_Event*)event
{
    if (_enabled) {
        for (AP_Touch* touch in touches) {
            _touch = touch;
            self.highlighted = YES;
            [self dispatchEvent:UIControlEventTouchDown];
            return;
        }
    }
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(AP_Event*)event
{
    for (AP_Touch* touch in touches) {
        if (touch == _touch) {
            _touch = nil;
            self.highlighted = NO;
            [self dispatchEvent:UIControlEventTouchCancel];
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(AP_Event*)event
{
    for (AP_Touch* touch in touches) {
        if (touch == _touch) {
            _touch = nil;
            self.highlighted = NO;
            CGPoint p = [touch locationInView:self];
            BOOL inside = [self pointInside:p withEvent:event];
            [self dispatchEvent:(inside ? UIControlEventTouchUpInside : UIControlEventTouchUpOutside)];
        }
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(AP_Event*)event
{
    for (AP_Touch* touch in touches) {
        if (touch == _touch) {
            CGPoint p = [touch locationInView:self];
            BOOL wasInside = self.highlighted;
            BOOL inside = [self pointInside:p withEvent:event];
            self.highlighted = inside;
            if (inside != wasInside) {
                [self dispatchEvent:(inside ? UIControlEventTouchDragEnter : UIControlEventTouchDragExit)];
            }
            [self dispatchEvent:(inside ? UIControlEventTouchDragInside : UIControlEventTouchDragOutside)];
        }
    }
}

@end
