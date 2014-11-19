/*
 *  Copyright (c) 2014 Translation Exchange, Inc. http://translationexchange.com All rights reserved.
 *
 *  _______                  _       _   _             ______          _
 * |__   __|                | |     | | (_)           |  ____|        | |
 *    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
 *    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
 *    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
 *    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
 *                                                                                        __/ |
 *                                                                                       |___/
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */


#import "Tr8nTranslatorViewController.h"
#import "Tr8n.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface Tr8nTranslatorViewController ()

@property(nonatomic, strong) UIWebView *webView;

@property(nonatomic, strong) NSString *translationKey;


- (IBAction) reloadButtonPressed: (id) sender;
- (IBAction) backButtonPressed: (id) sender;
- (IBAction) nextButtonPressed: (id) sender;
- (IBAction) actionButtonPressed: (id) sender;

@end

@implementation Tr8nTranslatorViewController

@synthesize webView, translationKey;

+ (void) toggleInAppTranslationsFromController:(UIViewController *) controller {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];

    [Tr8n configuration].inContextTranslatorEnabled = ![Tr8n configuration].inContextTranslatorEnabled;
    
    if ([Tr8n configuration].inContextTranslatorEnabled)
        hud.labelText = Tr8nLocalizedString(@"In-app translator enabled");
    else
        hud.labelText = Tr8nLocalizedString(@"In-app translator disabled");
    
    [[NSNotificationCenter defaultCenter] postNotificationName: Tr8nTranslationsLoadedNotification object: [Tr8n configuration].currentLocale];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [hud hide:YES];
    });
}

+ (void) translateFromController:(UIViewController *) controller withOptions: (NSDictionary *) options {
    Tr8nApplication *app = [Tr8n sharedInstance].currentApplication;

    if (![Tr8nConfiguration isHostAvailable:[app.tools valueForKey:@"host"]]) {
        [[[UIAlertView alloc] initWithTitle: @"Translation Center"
                                    message: @"You are not currently conntected to the internet. Please enable connection and try again."
                                   delegate: self
                          cancelButtonTitle: @"OK"
                          otherButtonTitles: nil] show];
    }
        
    Tr8nTranslatorViewController *translator = [[Tr8nTranslatorViewController alloc] init];
    translator.translationKey = [options objectForKey:@"translation_key"];
    [controller presentViewController:translator animated: YES completion: nil];
}

+ (void) translateFromController:(UIViewController *) controller {
    Tr8nTranslatorViewController *translator = [[Tr8nTranslatorViewController alloc] init];
    [controller presentViewController:translator animated: YES completion: nil];
}

- (void) loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 25, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:Tr8nLocalizedString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(dismiss:)];
    
    UINavigationItem *titleItem = [[UINavigationItem alloc] initWithTitle:Tr8nLocalizedString(@"Translate")];
    titleItem.leftBarButtonItem=doneButton;
    navBar.items = @[titleItem];
    [self.view addSubview:navBar];

    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 70, self.view.frame.size.width, self.view.frame.size.height - 70)];
    [self.webView  setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
}

- (NSString *) host {
    Tr8nApplication *app = [Tr8n sharedInstance].currentApplication;
    NSString *host = [app.tools objectForKey: @"host"];
    if(!host) host = @"http://tools.translationexchange.com";
    return host;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    Tr8nApplication *app = [Tr8n sharedInstance].currentApplication;
    Tr8nLanguage *lang = [Tr8n sharedInstance].currentLanguage;
    
    NSString *url = nil;

    if (self.translationKey) {
        url = [NSString stringWithFormat:@"%@/mobile?locale=%@&key=%@&translation_key=%@", [self host], lang.locale, app.key, self.translationKey];
    } else {
        url = [NSString stringWithFormat:@"%@/mobile?locale=%@&key=%@", [self host], lang.locale, app.key];
    }
    
    NSLog(@"url %@", url);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    if (request != nil) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [self.webView loadRequest:request];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *path = request.URL.path;
    if (path && [path rangeOfString:@"dismiss"].location != NSNotFound) {
        [self dismiss:self];
        return NO;
    }
    
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (IBAction) backButtonPressed: (id) sender {
    [self.webView goBack];
}

- (IBAction) nextButtonPressed: (id) sender {
    [self.webView goForward];
}

- (IBAction) actionButtonPressed: (id) sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[self.webView.request URL] absoluteString]]];
}

- (IBAction) reloadButtonPressed: (id) sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.webView reload];
}

-(IBAction)dismiss:(id)sender {
    [Tr8n reloadTranslations];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
