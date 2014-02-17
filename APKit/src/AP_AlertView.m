#import "AP_AlertView.h"

#import <UIKit/UIKit.h>

#import "AP_Application.h"
#import "AP_Button.h"
#import "AP_Check.h"
#import "AP_Label.h"
#import "AP_Window.h"

@implementation AP_AlertView {
    id<AP_AlertViewDelegate> _delegate;
    AP_Label* _header;
    AP_Label* _body;
    NSMutableArray* _buttons;
    AP_View* _alert;
    AP_Control* _vignette;
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

        _vignette = [[AP_Control alloc] initWithFrame:self.bounds];
        _vignette.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [_vignette addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_vignette];

        _alert = [[AP_View alloc] init];
        _alert.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        [self addSubview:_alert];

        _alert = [[AP_View alloc] init];
        _alert.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        [self addSubview:_alert];

        UIFont* bold = [UIFont fontWithName:@"Helvetica-Bold" size:20];
        UIFont* plain = [UIFont fontWithName:@"Helvetica" size:17];

        if (title) {
            _header = [[AP_Label alloc] init];
            _header.font = bold;
            _header.text = title;
            _header.textAlignment = NSTextAlignmentCenter;
            [self addSubview:_header];
        }
        
        if (message) {
            _body = [[AP_Label alloc] init];
            _body.font = plain;
            _body.text = message;
            _body.textAlignment = NSTextAlignmentCenter;
            [self addSubview:_body];
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
        UIColor* blank = [UIColor colorWithWhite:0 alpha:0];

        _buttons = [NSMutableArray array];
        for (NSString* name in buttonNames) {
            AP_Button* button = [[AP_Button alloc] init];
            button.titleLabel.font = bold;
            [button setTitle:name forState:UIControlStateNormal];
            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

            [button setTitleShadowColor:blank forState:UIControlStateNormal];

            [button setTitleColor:lightBlue forState:UIControlStateNormal];
            [button setTitleColor:white forState:UIControlStateHighlighted];

            [button setBackgroundColor:blank forState:UIControlStateNormal];
            [button setBackgroundColor:darkBlue forState:UIControlStateHighlighted];

            [_buttons addObject:button];
            [self addSubview:button];
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
#ifdef ANDROID
    id root = [AP_Application sharedApplication].delegate.window.rootViewController;
#else
    id root = [UIApplication sharedApplication].delegate.window.rootViewController;
#endif
    AP_CHECK([root isKindOfClass:[AP_Window class]], abort());
    AP_Window* window = (AP_Window*)root;
    [window resetAllGestures];

    self.alpha = 0;
    self.transform = CGAffineTransformMakeScale(0.25, 0.25);
    _vignette.transform = CGAffineTransformMakeScale(4, 4);
    [window.rootViewController.view addSubview:self];
    [AP_View animateWithDuration:0.25 animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
        _vignette.transform = CGAffineTransformIdentity;
    }];

    [[AP_Application sharedApplication].delegate addBackCloseBlock:^() {
        [self backButtonPressed];
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
    [[AP_Application sharedApplication].delegate removeLastBackButtonBlock];

    int i = (button == _vignette) ? 0 : [_buttons indexOfObjectIdenticalTo:button];
    [_delegate alertView:self clickedButtonAtIndex:i];
}

- (void) backButtonPressed
{
    [self hide];
    [_delegate alertView:self clickedButtonAtIndex:0];
}

- (void) layoutSubviews
{
    CGRect screenRect = self.bounds;
    _vignette.frame= screenRect;

    CGSize maxSize = {
        [AP_Window iPhone:250 iPad:350 iPadLandscape:400],
        screenRect.size.height,
    };

    CGSize headerSize = CGSizeZero;
    CGSize bodySize = CGSizeZero;
    CGSize buttonSize = CGSizeZero;

    // Measure how much space everything needs

    const CGFloat xSpace = [AP_Window iPhone:20 iPad:25 iPadLandscape:35];
    const CGFloat ySpace = [AP_Window iPhone:15 iPad:25 iPadLandscape:20];

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

    for (AP_Button* button in _buttons) {
        CGSize size = [button.titleLabel sizeThatFits:maxSize];
        buttonSize.height = MAX(buttonSize.height, size.height + 2 * ySpace);
        alertFrame.size.width = MAX(
            alertFrame.size.width,
            _buttons.count * (size.width + 2 * xSpace));
    }
    buttonSize.width = alertFrame.size.width / _buttons.count;

    alertFrame.size.height += buttonSize.height;

    // Now lay everything out

    alertFrame.origin.x = (screenRect.size.width - alertFrame.size.width) * 0.5;
    alertFrame.origin.y = (screenRect.size.height - alertFrame.size.height) * 0.4;
    _alert.frame = alertFrame;

    CGPoint pos = alertFrame.origin;
    pos.y += ySpace;

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
    for (AP_Button* button in _buttons) {
        button.frame = CGRectMake(pos.x, pos.y, buttonSize.width, buttonSize.height);
        pos.x += buttonSize.width;
    }
}

@end
