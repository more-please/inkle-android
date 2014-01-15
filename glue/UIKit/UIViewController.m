#import "UIViewController.h"

@implementation UIViewController

- (void) draw
{
    NSLog(@"[UIViewController draw]");
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    NSLog(@"[UIViewController touchesBegan]");
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    NSLog(@"[UIViewController touchesCancelled]");
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    NSLog(@"[UIViewController touchesEnded]");
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    NSLog(@"[UIViewController touchesMoved]");
}

- (void) resetTouches
{
    NSLog(@"[UIViewController resetTouches]");
}

@end
