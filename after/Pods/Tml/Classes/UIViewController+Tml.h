/*
 *  Copyright (c) 2015 Translation Exchange, Inc. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIView.h>
#import "TmlLanguage.h"
#import "TmlApplication.h"

@interface UIViewController (Tml)

- (NSString *) tr8nSourceKey;

- (TmlLanguage *) tr8nDefaultLanguage;

- (TmlLanguage *) tr8nCurrentLanguage;

- (TmlApplication *) tr8nCurrentApplication;

- (NSObject *) tr8nCurrentUser;

- (void) setTextValue: (NSObject *) value toField: (id) field;

- (void) translateView: (UIView *) view;

- (void) translateView: (UIView *) view withLabel: (NSString *) label description: (NSString *) description tokens: (NSDictionary *) tokens options: (NSDictionary *) options;

@end

#define TmlLocalizeView(view) \
[self translateView: view]

#define TmlLocalizeViewWithLabel(view, label) \
[self translateView: view withLabel: label description: nil tokens: @{} options: @{}]

#define TmlLocalizeViewWithLabelAndTokens(view, label, the_tokens) \
[self translateView: view withLabel: label description: nil tokens: the_tokens options: @{}]

#define TmlLocalizeViewWithLabelAndDescription(view, label, desc) \
[self translateView: view withLabel: label description: desc tokens: @{} options: @{}]

#define TmlLocalizeViewWithLabelAndDescriptionAndTokens(view, label, description, tokens) \
[self translateView: view withLabel: label description: description tokens: tokens options: @{}]

#define TmlLocalizeViewWithLabelAndDescriptionAndTokensAndOptions(view, label, description, tokens, options) \
[self translateView: view withLabel: label description: description tokens: tokens options: options]

