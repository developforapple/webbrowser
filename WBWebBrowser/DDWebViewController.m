//
//  DDWebViewController.m
//  QuizUp
//
//  Created by Normal on 15/11/19.
//  Copyright © 2015年 Bo Wang. All rights reserved.
//

#import "DDWebViewController.h"

static NSString *kWKWebViewProgressKeyPath = @"estimatedProgress";

@interface DDWebViewController ()
@property (strong, nonatomic) NSMutableArray<WKWebView *> *wkwebViewsAllFrame;
@property (strong, nonatomic) NSTimer *fakeProgressTimer;
@end

@interface DDWebViewController (WKWebView)
- (WKWebView *)createWKWebViewWithConfigure:(WKWebViewConfiguration *)configure;
- (void)setupWKWebView:(WKWebView *)webView;
- (void)invalidWKWebView:(WKWebView *)webView;
- (void)validWKWebView:(WKWebView *)webView;
@end

@interface DDWebViewController (UIWebView)
- (void)setupUIWebView:(UIWebView *)webView;
@end

@interface DDWebViewController (KVO)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context;
@end

@implementation DDWebViewController

#pragma mark - Initializers
+ (instancetype)webViewInstance
{
    DDWebViewController *vc = [[DDWebViewController alloc] init];
    return vc;
}

- (instancetype)init
{
    return [self initWithConfigure:nil];
}

- (instancetype)initWithConfigure:(WKWebViewConfiguration *)configure
{
    self = [super init];
    if (self) {
        if ([WKWebView class]) {
            _wkWebView = [self createWKWebViewWithConfigure:configure];
        }else{
            _uiWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
        }
    }
    return self;
}

- (void)setupWebView
{
    if (_wkWebView) {
        [self setupWKWebView:_wkWebView];
        [self validWKWebView:_wkWebView];
    }else{
        [self setupUIWebView:_uiWebView];
    }
}

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.wkwebViewsAllFrame = [NSMutableArray array];
    self.tintColor = RGBColor(255, 228, 0, 1);
    
    [self setupWebView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_progressDisplayedInView) {
        self.progressDisplayedInView = self.navigationController.navigationBar;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _uiWebView.delegate = nil;
    [self.progressView removeFromSuperview];
}

- (void)dealloc
{
    _uiWebView.delegate = nil;
    _wkWebView.navigationDelegate = nil;
    _wkWebView.UIDelegate = nil;
    [_wkWebView removeObserver:self forKeyPath:kWKWebViewProgressKeyPath];
}

#pragma mark - Getter
- (UIScrollView *)scrollView
{
    if (self.wkWebView) {
        return self.wkWebView.scrollView;
    }else{
        return self.uiWebView.scrollView;
    }
}

- (NSString *)URL
{
    if (self.wkWebView) {
        return [self.wkWebView URL].absoluteString;
    }
    return self.uiWebView.request.URL.absoluteString;
}

#pragma mark - Setter
- (UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [_progressView setTrackTintColor:[UIColor colorWithWhite:1 alpha:0.f]];
        [_progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    }
    return _progressView;
}

- (void)setProgressDisplayedInView:(UIView *)progressDisplayedInView
{
    _progressDisplayedInView = progressDisplayedInView;
    if (progressDisplayedInView) {
        [self.progressView removeFromSuperview];
        [progressDisplayedInView addSubview:self.progressView];
        self.progressView.frame = CGRectMake(
                                         0,
                                         CGRectGetHeight(progressDisplayedInView.frame)-CGRectGetHeight(self.progressView.frame),
                                         CGRectGetWidth(progressDisplayedInView.frame),
                                         CGRectGetHeight(self.progressView.frame)
                                         );
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    self.progressView.tintColor = tintColor;
}

#pragma mark - Control
- (void)stopLoading
{
    if (_wkWebView) {
        [_wkWebView stopLoading];
    }else{
        [_uiWebView stopLoading];
    }
}

- (void)reload
{
    if (_wkWebView) {
        [_wkWebView reload];
    }else{
        [_uiWebView reload];
    }
}

- (BOOL)canGoForward
{
    if (_wkWebView) {
        return [_wkWebView canGoForward];
    }
    return [_uiWebView canGoForward];
}

- (void)goForward
{
    if (_wkWebView) {
        [_wkWebView goForward];
    }else{
        [_uiWebView goForward];
    }
}

- (BOOL)canGoBack
{
    if (_wkWebView) {
        BOOL cangoback = [_wkWebView canGoBack];
        if (!cangoback) {
            cangoback = self.wkwebViewsAllFrame.count!=0;
        }
        return cangoback;
    }
    return [_uiWebView canGoBack];
}

- (void)goBack
{
    if (_wkWebView) {
        
        if ([_wkWebView canGoBack]) {
            [_wkWebView goBack];
        }else if (self.wkwebViewsAllFrame.count != 0){
            WKWebView *lastWebView = [self.wkwebViewsAllFrame lastObject];
            WKWebView *curWebView = self.wkWebView;
            
            [self validWKWebView:lastWebView];
            [self invalidWKWebView:curWebView];
            [curWebView removeFromSuperview];
            
            _wkWebView = lastWebView;
            [self.wkwebViewsAllFrame removeObject:lastWebView];
            
            if ([self.delegate respondsToSelector:@selector(webViewController:didStartLoadingURL:)]) {
                [self.delegate webViewController:self didStartLoadingURL:_wkWebView.URL];
            }
        }
    }else{
        [_uiWebView goBack];
    }
}

- (void)loadURL:(NSURL *)URL
{
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    if (_wkWebView) {
        [_wkWebView loadRequest:request];
    }else{
        [_uiWebView loadRequest:request];
    }
}

- (void)loadURLString:(NSString *)URLString
{
    [self loadURL:[NSURL URLWithString:URLString]];
}

- (void)removeDelegates
{
    self.scrollView.delegate = nil;
    [self.wkwebViewsAllFrame enumerateObjectsUsingBlock:^(WKWebView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.UIDelegate = nil;
        obj.navigationDelegate = nil;
        obj.scrollView.delegate = nil;
    }];
    self.delegate = nil;
}

#pragma mark - JS
- (void)runJSCode:(NSString *)js completion:(DDEvaluateJSCompletion)completion
{
    if (_wkWebView) {
        [_wkWebView evaluateJavaScript:js completionHandler:completion];
    }else{
        NSString *string = [_uiWebView stringByEvaluatingJavaScriptFromString:js];
        if (completion) {
            completion(string,nil);
        }
    }
}

@end

#pragma mark - WKWebView
@implementation DDWebViewController (WKWebView)
- (WKWebView *)createWKWebViewWithConfigure:(WKWebViewConfiguration *)configure
{
    WKWebView *webView;
    if (!configure) {
        webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    }else{
        webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configure];
    }
    return webView;
}

- (void)setupWKWebView:(WKWebView *)webView
{
    [webView setFrame:self.view.bounds];
    [webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [webView setNavigationDelegate:self];
    [webView setUIDelegate:self];
    [webView setMultipleTouchEnabled:YES];
    [webView setAutoresizesSubviews:YES];
    [webView setAllowsBackForwardNavigationGestures:YES];
    [webView.scrollView setAlwaysBounceVertical:YES];
    [self.view addSubview:webView];
}

- (void)invalidWKWebView:(WKWebView *)webView
{
    webView.hidden = YES;
    webView.UIDelegate = nil;
    webView.navigationDelegate = nil;
    webView.scrollView.delegate = nil;
    [webView removeObserver:self forKeyPath:kWKWebViewProgressKeyPath];
}

- (void)validWKWebView:(WKWebView *)webView
{
    webView.hidden = NO;
    [webView addObserver:self forKeyPath:kWKWebViewProgressKeyPath options:0 context:NULL];
    [webView.superview bringSubviewToFront:webView];
}

#pragma mark Delegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"%s,%@",__FUNCTION__,navigation);
    if (webView == self.wkWebView) {
        if ([self.delegate respondsToSelector:@selector(webViewController:didStartLoadingURL:)]) {
            [self.delegate webViewController:self didStartLoadingURL:webView.URL];
        }
        
        [self.progressView setProgress:.1f animated:YES];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"%s,%@,%@",__FUNCTION__,navigation,error);
    if (webView == self.wkWebView) {
        if ([self.delegate respondsToSelector:@selector(webViewController:didFailToLoadURL:error:)]) {
            [self.delegate webViewController:self didFailToLoadURL:webView.URL error:error];
        }
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    NSLog(@"%s,%@",__FUNCTION__,navigation);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"%s,%@",__FUNCTION__,navigation);
    if (webView == self.wkWebView) {
        if ([self.delegate respondsToSelector:@selector(webViewController:didFinishLoadingURL:)]) {
            [self.delegate webViewController:self didFinishLoadingURL:webView.URL];
        }
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"%s:%@,%@",__FUNCTION__,navigation,error);
    if (webView == self.wkWebView) {
        if ([self.delegate respondsToSelector:@selector(webViewController:didFailToLoadURL:error:)]) {
            [self.delegate webViewController:self didFailToLoadURL:webView.URL error:error];
        }
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"%s:%@",__FUNCTION__,navigationAction);
    
    NSURL *URL = navigationAction.request.URL;

    /**
     *  safari 不支持swf视频文件，需要屏蔽。参考请求这个链接：http://36kr.com/p/5041098.html
     */
    NSString *extension = [URL pathExtension];
    if ([extension isEqualToString:@"swf"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    NSString *scheme = URL.scheme;
    if (scheme.length != 0 && ![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"ftp"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSLog(@"%s:%@",__FUNCTION__,navigationResponse.response.URL);
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler
{
    NSLog(@"%s",__FUNCTION__);
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"%s:%@",__FUNCTION__,navigation);
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    NSLog(@"%s\n%@\n%@\n%@",__FUNCTION__,configuration,navigationAction,windowFeatures);
    
    if (navigationAction.request.URL.absoluteString.length != 0) {
        [webView loadRequest:navigationAction.request];
        return nil;
    }
    
    WKWebView *targetWebView = [self createWKWebViewWithConfigure:configuration];
    [self setupWKWebView:targetWebView];
    [self validWKWebView:targetWebView];
    [self invalidWKWebView:self.wkWebView];
    [self.wkwebViewsAllFrame addObject:self.wkWebView];
    _wkWebView = targetWebView;
    return targetWebView;
}

@end

#pragma mark - UIWebView
@implementation DDWebViewController (UIWebView)
- (void)setupUIWebView:(UIWebView *)webView
{
    [webView setFrame:self.view.bounds];
    [webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [webView setDelegate:self];
    [webView setMultipleTouchEnabled:YES];
    [webView setAutoresizesSubviews:YES];
    [webView setScalesPageToFit:YES];
    [webView.scrollView setAlwaysBounceVertical:YES];
    [self.view addSubview:webView];
}

#pragma mark Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if(webView == _uiWebView) {
        NSString *scheme = request.URL.scheme;
        if (scheme.length != 0 && ![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) {
            return NO;
        }
        
        [self fakeProgressViewStartLoading];
        
        if ([self.delegate respondsToSelector:@selector(webViewController:didStartLoadingURL:)]) {
            [self.delegate webViewController:self didStartLoadingURL:request.URL];
        }
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if(webView == _uiWebView) {
        if(!_uiWebView.isLoading) {
            [self fakeProgressBarStopLoading];
        }
        if ([self.delegate respondsToSelector:@selector(webViewController:didFinishLoadingURL:)]) {
            [self.delegate webViewController:self didFinishLoadingURL:webView.request.URL];
        }
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (webView == _uiWebView) {
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(webView == _uiWebView) {
        if(!_uiWebView.isLoading) {
            [self fakeProgressBarStopLoading];
        }
        if ([self.delegate respondsToSelector:@selector(webViewController:didFailToLoadURL:error:)]) {
            [self.delegate webViewController:self didFailToLoadURL:webView.request.URL error:error];
        }
    }
}

#pragma mark - Fake Progress Bar Control (UIWebView)

- (void)fakeProgressViewStartLoading
{
    [self.progressView setProgress:0.0f animated:NO];
    [self.progressView setAlpha:1.0f];
    
    if(!self.fakeProgressTimer) {
        self.fakeProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f target:self selector:@selector(fakeProgressTimerDidFire:) userInfo:nil repeats:YES];
    }
}

- (void)fakeProgressBarStopLoading {
    if(self.fakeProgressTimer) {
        [self.fakeProgressTimer invalidate];
    }
    
    if(self.progressView) {
        [self.progressView setProgress:1.0f animated:YES];
        [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.progressView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [self.progressView setProgress:0.0f animated:NO];
        }];
    }
}

- (void)fakeProgressTimerDidFire:(id)sender {
    CGFloat increment = 0.005/(self.progressView.progress + 0.2);
    if([_uiWebView isLoading]) {
        CGFloat progress = (self.progressView.progress < 0.75f) ? self.progressView.progress + increment : self.progressView.progress + 0.0005;
        if(self.progressView.progress < 0.95) {
            [self.progressView setProgress:progress animated:YES];
        }
    }
}

@end

#pragma mark - KVO
@implementation DDWebViewController (KVO)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kWKWebViewProgressKeyPath] && object == _wkWebView) {
        
        CGFloat progress = _wkWebView.estimatedProgress;
        
        self.progressView.hidden = NO;
        BOOL animated = progress > self.progressView.progress;
        [self.progressView setProgress:progress animated:animated];
        
        if (progress >= 1.f) {
            [UIView animateWithDuration:.3f delay:.3f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.progressView.hidden = YES;
            } completion:^(BOOL finished) {
                self.progressView.progress = 0;
            }];
        }
    }
}
@end
