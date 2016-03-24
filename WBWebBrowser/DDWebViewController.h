//
//  DDWebViewController.h
//  QuizUp
//
//  Created by Normal on 15/11/19.
//  Copyright © 2015年 Bo Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#define RGBColor(R,G,B,A) [UIColor colorWithRed:(R)/255.f green:(G)/255.f blue:(B)/255.f alpha:(A)]

@class DDWebViewController;

@protocol DDWebViewControllerDelegate <NSObject>
@optional
- (void)webViewController:(DDWebViewController *)vc didStartLoadingURL:(NSURL *)URL;
- (void)webViewController:(DDWebViewController *)vc didFinishLoadingURL:(NSURL *)URL;
- (void)webViewController:(DDWebViewController *)vc didFailToLoadURL:(NSURL *)URL error:(NSError *)error;
@end

typedef void(^DDEvaluateJSCompletion)(id obj,NSError *err);

@interface DDWebViewController : UIViewController <UIWebViewDelegate,WKNavigationDelegate,WKUIDelegate>

+ (instancetype)webViewInstance;

#pragma mark - WebView
@property (strong, readonly, nonatomic) UIWebView *uiWebView;
@property (strong, readonly, nonatomic) WKWebView *wkWebView;
@property (strong, readonly, nonatomic) UIScrollView *scrollView;

@property (strong, readonly, nonatomic) NSString *URL;

@property (weak, nonatomic) id<DDWebViewControllerDelegate> delegate;

#pragma mark - ProgressView
/**
 *  进度条
 */
@property (strong, nonatomic) UIProgressView *progressView;
/**
 *  进度条显示的view。默认是导航栏
 */
@property (strong, nonatomic) UIView *progressDisplayedInView;

#pragma mark - Control
- (void)stopLoading;
- (void)reload;
- (BOOL)canGoForward;
- (void)goForward;
- (BOOL)canGoBack;
- (void)goBack;
- (void)loadURL:(NSURL *)URL;
- (void)loadURLString:(NSString *)URLString;

- (void)removeDelegates;

#pragma mark - Style
@property (strong, nonatomic) UIColor *tintColor;

#pragma mark - js
- (void)runJSCode:(NSString *)js completion:(DDEvaluateJSCompletion)completion;

@end
