#import "UIViewController.h"

@implementation Real_UIViewController

- (BOOL) update
{
    NSLog(@"[UIViewController update]");
    return NO;
}

- (void) draw
{
    NSLog(@"[UIViewController draw]");
}

- (void) touchesBegan:(NSSet*)touches withEvent:(Real_UIEvent*)event
{
    NSLog(@"[UIViewController touchesBegan]");
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(Real_UIEvent*)event
{
    NSLog(@"[UIViewController touchesCancelled]");
}

- (void) touchesEnded:(NSSet*)touches withEvent:(Real_UIEvent*)event
{
    NSLog(@"[UIViewController touchesEnded]");
}

- (void) touchesMoved:(NSSet*)touches withEvent:(Real_UIEvent*)event
{
    NSLog(@"[UIViewController touchesMoved]");
}

- (void) resetTouches
{
    NSLog(@"[UIViewController resetTouches]");
}

- (void) mouseMoved:(CGPoint)pos withEvent:(Real_UIEvent*)event
{
    NSLog(@"[UIViewController mouseMoved]");
}

@end
