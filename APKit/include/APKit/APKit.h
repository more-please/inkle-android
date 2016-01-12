#pragma once

#ifdef AP_REPLACE_UI

#import "AP_Check.h"
#import "AP_Log.h"

#import "AP_ActivityIndicatorView.h"
#import "AP_ActivityViewController.h"
#import "AP_AlertView.h"
#import "AP_Application.h"
#import "AP_BookView.h"
#import "AP_Button.h"
#import "AP_Bundle.h"
#import "AP_Checkbox.h"
#import "AP_Control.h"
#import "AP_Event.h"
#import "AP_Font.h"
#import "AP_GestureRecognizer.h"
#import "AP_GLKBaseEffect.h"
#import "AP_GLKEffectPropertyTexture.h"
#import "AP_GLKEffectPropertyTransform.h"
#import "AP_GLKTextureLoader.h"
#import "AP_GLKView.h"
#import "AP_GLKViewController.h"
#import "AP_Image.h"
#import "AP_ImageView.h"
#import "AP_Label.h"
#import "AP_Layer.h"
#import "AP_NavigationController.h"
#import "AP_PageViewController.h"
#import "AP_ScrollView.h"
#import "AP_StrongCache.h"
#import "AP_TextField.h"
#import "AP_Touch.h"
#import "AP_View.h"
#import "AP_ViewController.h"
#import "AP_WeakCache.h"
#import "AP_WeakSet.h"
#import "AP_WebView.h"
#import "AP_Window.h"

#import "AP_Bundle.h"
#import "AP_GLBuffer.h"
#import "AP_GLProgram.h"
#import "AP_GLTexture.h"
#import "AP_Profiler.h"
#import "AP_UserDefaults.h"

#import "APKit_main.h"

#import "NSAttributedString+Attributes.h"
#import "NSDictionary+AP_InitWithData.h"
#import "NSObject+AP_PerformBlock.h"
#import "NSObject+AP_RoundRect.h"
#import "NSObject+debugDescription.h"
#import "NSString+sizeWithFont.h"

#define UIActivityIndicatorView        AP_ActivityIndicatorView
#define UIActivityViewController       AP_ActivityViewController
#define UIAlertView                    AP_AlertView
#define UIAlertViewDelegate            AP_AlertViewDelegate
#define UIApplication                  AP_Application
#define UIApplicationDelegate          AP_ApplicationDelegate
#define UIButton                       AP_Button
#define UIControl                      AP_Control
#define UIEvent                        AP_Event
#define UIFont                         AP_Font
#define UIGestureRecognizer            AP_GestureRecognizer
#define UIGestureRecognizerDelegate    AP_GestureRecognizerDelegate
#define UILongPressGestureRecognizer   AP_LongPressGestureRecognizer
#define UIPanGestureRecognizer         AP_PanGestureRecognizer
#define UIPinchGestureRecognizer       AP_PinchGestureRecognizer
#define UITapGestureRecognizer         AP_TapGestureRecognizer
#define GLKBaseEffect                  AP_GLKBaseEffect
#define GLKVertexAttribPosition        AP_GLKVertexAttribPosition
#define GLKVertexAttribTexCoord0       AP_GLKVertexAttribTexCoord0
#define GLKEffectPropertyTexture       AP_GLKEffectPropertyTexture
#define GLKEffectPropertyTransform     AP_GLKEffectPropertyTransform
#define GLKTextureInfo                 AP_GLKTextureInfo
#define GLKTextureLoader               AP_GLKTextureLoader
#define GLKView                        AP_GLKView
#define GLKViewController              AP_GLKViewController
#define UIImage                        AP_Image
#define UIImageView                    AP_ImageView
#define UILabel                        AP_Label
#define CALayer                        AP_Layer
#define UINavigationController         AP_NavigationController
#define UINavigationControllerDelegate AP_NavigationControllerDelegate
#define UIPageViewController           AP_PageViewController
#define UIPageViewControllerDataSource AP_PageViewControllerDataSource
#define UIPageViewControllerDelegate   AP_PageViewControllerDelegate
#define UIScrollView                   AP_ScrollView
#define UIScrollViewDelegate           AP_ScrollViewDelegate
#define UITextField                    AP_TextField
#define UITextFieldDelegate            AP_TextFieldDelegate
#define UITouch                        AP_Touch
#define UIView                         AP_View
#define UIViewController               AP_ViewController
#define UIWebView                      AP_WebView
#define UIWebViewDelegate              AP_WebViewDelegate
#define UIWindow                       AP_Window
#define UIResponder                    AP_Responder

#define NSBundle                       AP_Bundle
#define NSUserDefaults                 AP_UserDefaults

#else

// Don't replace UI -- just map all the AP_* classes to their UI* equivalents.
// We use #define because typedef doesn't work for protocols.

#define AP_ActivityIndicatorView        UIActivityIndicatorView
#define AP_AlertView                    UIAlertView
#define AP_AlertViewDelegate            UIAlertViewDelegate
#define AP_Application                  UIApplication
#define AP_ApplicationDelegate          UIApplicationDelegate
#define AP_Button                       UIButton
#define AP_Bundle                       NSBundle
#define AP_Control                      UIControl
#define AP_Event                        UIEvent
#define AP_Font                         UIFont
#define AP_GestureRecognizer            UIGestureRecognizer
#define AP_GestureRecognizerDelegate    UIGestureRecognizerDelegate
#define AP_LongPressGestureRecognizer   UILongPressGestureRecognizer
#define AP_PanGestureRecognizer         UIPanGestureRecognizer
#define AP_PinchGestureRecognizer       UIPinchGestureRecognizer
#define AP_TapGestureRecognizer         UITapGestureRecognizer
#define AP_GLKBaseEffect                GLKBaseEffect
#define AP_GLKVertexAttribPosition      GLKVertexAttribPosition
#define AP_GLKVertexAttribTexCoord0     GLKVertexAttribTexCoord0
#define AP_GLKEffectPropertyTexture     GLKEffectPropertyTexture
#define AP_GLKEffectPropertyTransform   GLKEffectPropertyTransform
#define AP_GLKView                      GLKView
#define AP_GLKViewController            GLKViewController
#define AP_Image                        UIImage
#define AP_ImageView                    UIImageView
#define AP_Label                        UILabel
#define AP_Layer                        CALayer
#define AP_NavigationController         UINavigationController
#define AP_NavigationControllerDelegate UINavigationControllerDelegate
#define AP_PageViewController           UIPageViewController
#define AP_PageViewControllerDataSource UIPageViewControllerDataSource
#define AP_PageViewControllerDelegate   UIPageViewControllerDelegate
#define AP_ScrollView                   UIScrollView
#define AP_ScrollViewDelegate           UIScrollViewDelegate
#define AP_TextField                    UITextField
#define AP_TextFieldDelegate            UITextFieldDelegate
#define AP_Touch                        UITouch
#define AP_View                         UIView
#define AP_ViewController               UIViewController
#define AP_WebView                      UIWebView
#define AP_WebViewDelegate              UIWebViewDelegate
#define AP_Window                       UIWindow

#endif
