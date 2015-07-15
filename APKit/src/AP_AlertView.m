#import "AP_AlertView.h"

#import <UIKit/UIKit.h>

#import "AP_Application.h"
#import "AP_Button.h"
#import "AP_Check.h"
#import "AP_Label.h"
#import "AP_Layer.h"
#import "AP_Window.h"

@implementation AP_AlertView {
    AP_Label* _header;
    AP_Label* _body;
    NSMutableArray* _buttons;
    AP_View* _alert;
    AP_Control* _vignette;
    AP_Control* _backstop; // Catch gestures during opening animation.
}

AP_BAN_EVIL_INIT;

- (id) initWithTitle:(NSString*)title
        message:(NSString*)message
        delegate:(id<AP_AlertViewDelegate>)delegate
        cancelButtonTitle:(NSString*)cancelButtonTitle
        otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    CGRect r = [AP_Window screenBounds];
    self = [super initWithFrame:r];
    if (self) {
        self.autoresizingMask = -1;
        _delegate = delegate;

        _backstop = [[AP_Control alloc] initWithFrame:self.bounds];
        _backstop.backgroundColor = [UIColor clearColor];
        [self addSubview:_backstop];

        _vignette = [[AP_Control alloc] initWithFrame:self.bounds];
        _vignette.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [_vignette addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_vignette];

        _alert = [[AP_View alloc] init];
        _alert.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1];
        _alert.layer.cornerRadius = 14;
        [self addSubview:_alert];

#ifdef SORCERY
        AP_Font* headerFont = [AP_Font fontWithName:@"Helvetica" size:20];
        AP_Font* bodyFont = [AP_Font fontWithName:@"Helvetica" size:17];
        AP_Font* buttonFont = [AP_Font fontWithName:@"Helvetica-Bold" size:20];
#else
        AP_Font* headerFont = [AP_Font fontWithName:@"Futura-Medium" size:20];
        AP_Font* bodyFont = [AP_Font fontWithName:@"Futura-Medium" size:17];
        AP_Font* buttonFont = [AP_Font fontWithName:@"Futura-CondensedMedium" size:20];
#endif

        if (title) {
            _header = [[AP_Label alloc] init];
            _header.font = headerFont;
            _header.text = title;
            _header.textAlignment = NSTextAlignmentCenter;
            _header.textColor = [UIColor whiteColor];
            [_alert addSubview:_header];
        }

        if (message) {
            _body = [[AP_Label alloc] init];
            _body.font = bodyFont;
            _body.text = message;
            _body.textAlignment = NSTextAlignmentCenter;
            _body.textColor = [UIColor colorWithWhite:0.75 alpha:1];
            _body.numberOfLines = 0;
            [_alert addSubview:_body];
        }

        NSMutableArray* buttonNames = [NSMutableArray array];

        [buttonNames addObject:cancelButtonTitle];

        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString* arg = otherButtonTitles; arg; arg = va_arg(args, NSString*))
        {
            [buttonNames addObject:arg];
        }
        va_end(args);

        // See http://developer.android.com/design/style/color.html
        UIColor* lightBlue = [UIColor colorWithRed:(0x33 / 255.0) green:(0xb5 / 255.0) blue:(0xe5 / 255.0) alpha:1];
        UIColor* darkBlue = [UIColor colorWithRed:(0x00 / 255.0) green:(0x99 / 255.0) blue:(0xcc / 255.0) alpha:1];
        UIColor* white = [UIColor whiteColor];
        UIColor* black = [UIColor blackColor];
        UIColor* empty = [UIColor colorWithWhite:0 alpha:0];

        _buttons = [NSMutableArray array];
        for (NSString* name in buttonNames) {
            AP_Button* button = [[AP_Button alloc] init];
            button.titleLabel.font = buttonFont;
            button.titleLabel.shadowOffset = CGSizeMake(0, 1);

            [button setTitle:name forState:UIControlStateNormal];
            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

            [button setTitleColor:white forState:UIControlStateNormal];
            [button setTitleShadowColor:black forState:UIControlStateNormal];

            [button setTitleColor:empty forState:UIControlStateHighlighted];
            [button setTitleShadowColor:white forState:UIControlStateHighlighted];

            [button setBackgroundColor:empty forState:UIControlStateNormal];
            [button setBackgroundColor:darkBlue forState:UIControlStateHighlighted];

            button.layer.cornerRadius = 14;

            [_buttons addObject:button];
            [_alert addSubview:button];
        }

        [self layoutIfNeeded];
    }
    return self;
}

- (NSString*) buttonTitleAtIndex:(NSInteger)i
{
    AP_Button* button = [_buttons objectAtIndex:i];
    return button.titleLabel.text.copy;
}

- (void) show
{
    id root = [AP_Application sharedApplication].delegate.window.rootViewController;

    AP_CHECK([root isKindOfClass:[AP_Window class]], abort());
    AP_Window* window = (AP_Window*)root;
    [window resetAllGestures];

    _vignette.alpha = 0;
    _alert.alpha = 0;
    _alert.transform = CGAffineTransformMakeScale(0.25, 0.25);
    [window.rootViewController.view addSubview:self];

    [AP_View animateWithDuration:0.25 animations:^{
        _vignette.alpha = 1;
        _alert.alpha = 1;
        _alert.transform = CGAffineTransformIdentity;
    }];
}

- (void) hide
{
    [AP_View animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeScale(0.25, 0.25);
        _vignette.transform = CGAffineTransformMakeScale(4, 4);
        self.alpha = 0;
    } completion:^(BOOL finished){
        [self removeFromSuperview];
    }];
}

- (void) buttonPressed:(AP_View*)button
{
    [self hide];
    int i = (button == _vignette) ? 0 : [_buttons indexOfObjectIdenticalTo:button];
    [_delegate alertView:self clickedButtonAtIndex:i];
}

- (BOOL) handleAndroidBackButton
{
    [self hide];
    [_delegate alertView:self clickedButtonAtIndex:0];
    return YES;
}

- (void) layoutSubviews
{
    CGRect screenRect = self.bounds;
    _vignette.frame = screenRect;

    CGSize maxSize = {
        [AP_Window iPhone:250 iPad:350 iPadLandscape:400],
        screenRect.size.height,
    };

    CGSize headerSize = CGSizeZero;
    CGSize bodySize = CGSizeZero;
    CGSize buttonSize = CGSizeZero;

    // Measure how much space everything needs

    const CGFloat xSpace = [AP_Window scaleForIPhone:20 iPad:25];
    const CGFloat ySpace = [AP_Window scaleForIPhone:15 iPad:20];

    CGRect alertFrame = CGRectZero;
    if (_header) {
        headerSize = [_header sizeThatFits:maxSize];
        alertFrame.size.width = MAX(alertFrame.size.width, headerSize.width);
        alertFrame.size.height += headerSize.height;
        alertFrame.size.height += ySpace;
    }
    if (_body) {
        bodySize = [_body sizeThatFits:maxSize];
        alertFrame.size.width = MAX(alertFrame.size.width, bodySize.width);
        alertFrame.size.height += bodySize.height;
        alertFrame.size.height += ySpace / 2;
    }

    alertFrame.size.height += ySpace;
    alertFrame.size.width += 2 * xSpace;

    BOOL verticalLayout = (_buttons.count > 2);
    int hCount = verticalLayout ? 1 : _buttons.count;
    int vCount = verticalLayout ? _buttons.count : 1;

    for (AP_Button* button in _buttons) {
        CGSize size = [button.titleLabel sizeThatFits:maxSize];
        buttonSize.height = MAX(buttonSize.height, size.height + 2 * ySpace);
        alertFrame.size.width = MAX(
            alertFrame.size.width,
            hCount * (size.width + 2 * xSpace));
    }

    buttonSize.width = alertFrame.size.width / hCount;
    alertFrame.size.height += vCount * buttonSize.height;

    // Now lay everything out

    alertFrame.origin.x = (screenRect.size.width - alertFrame.size.width) * 0.5;
    alertFrame.origin.y = (screenRect.size.height - alertFrame.size.height) * 0.4;
    _alert.frame = alertFrame;

    CGPoint pos = { 0, ySpace };
    if (_header) {
        _header.frame = CGRectMake(pos.x + xSpace, pos.y, alertFrame.size.width - 2 * xSpace, headerSize.height);
        pos.y += headerSize.height;
        pos.y += ySpace;
    }
    if (_body) {
        _body.frame = CGRectMake(pos.x + xSpace, pos.y, alertFrame.size.width - 2 * xSpace, bodySize.height);
        pos.y += bodySize.height;
        pos.y += ySpace / 2;
    }

    NSMutableArray* buttons = [_buttons mutableCopy];
    if (buttons.count > 2) {
        // Move cancel button to the end
        AP_Button* cancel = [buttons objectAtIndex:0];
        [buttons removeObjectAtIndex:0];
        [buttons addObject:cancel];
    }
    for (AP_Button* button in buttons) {
        button.frame = CGRectMake(pos.x, pos.y, buttonSize.width, buttonSize.height);
        if (verticalLayout) {
            pos.y += buttonSize.height;
        } else {
            pos.x += buttonSize.width;
        }
    }
}

@end
