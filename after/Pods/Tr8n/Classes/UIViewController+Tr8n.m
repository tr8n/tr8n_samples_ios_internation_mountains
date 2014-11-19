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

#import <UIKit/UIKit.h>
#import "UIViewController+Tr8n.h"
#import "Tr8n.h"
#import "Tr8nTranslatorViewController.h"

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <float.h>

NSString const *Tr8nViewData = @"Tr8nViewData";
NSString const *Tr8nKeyData = @"Tr8nKeyData";
NSString const *Tr8nViewTapRecognizer = @"Tr8nViewTapRecognizer";

@implementation UIViewController (Tr8n)

- (NSString *) tr8nSourceKey {
    return NSStringFromClass([self class]);
}

- (Tr8nLanguage *) tr8nDefaultLanguage {
    return [[Tr8n sharedInstance] defaultLanguage];
}

- (Tr8nLanguage *) tr8nCurrentLanguage {
    return [[Tr8n sharedInstance] currentLanguage];
}

- (Tr8nApplication *) tr8nCurrentApplication {
    return [[Tr8n sharedInstance] currentApplication];
}

- (NSObject *) tr8nCurrentUser {
    return [[Tr8n sharedInstance] currentUser];
}

- (void) setTextValue: (NSObject *) value toField: (id) field {
    if ([field isKindOfClass: UILabel.class]) {
        if ([value isKindOfClass: NSAttributedString.class])
            [((UILabel *) field) setAttributedText: (NSAttributedString *) value];
        else if ([value isKindOfClass: NSString.class])
            [((UILabel *) field) setText: (NSString *) value];
    } else if ([field isKindOfClass: UITextView.class]) {
        if ([value isKindOfClass: NSAttributedString.class])
            [((UITextView *) field) setAttributedText: (NSAttributedString *) value];
        else if ([value isKindOfClass: NSString.class])
            [((UITextView *) field) setText: (NSString *) value];
    } else if ([field isKindOfClass: UINavigationItem.class]) {
        if ([value isKindOfClass: NSAttributedString.class]) {
            UINavigationItem *navItem = (UINavigationItem *) field;
            UILabel *label = [[UILabel alloc] init];
            [label setAttributedText: (NSAttributedString *) value];
            [navItem setTitleView:label];
        } else if ([value isKindOfClass: NSString.class])
            [((UINavigationItem *) field) setTitle: (NSString *) value];
    }
}

- (NSValue *) viewHashKey: (UIView *) view {
    return [NSValue valueWithNonretainedObject:view];
}

- (NSDictionary *) originalViewValueForKey: (NSValue *) key {
    NSMutableDictionary *tr8nViewData = objc_getAssociatedObject(self, &Tr8nViewData);
    return [tr8nViewData objectForKey:key];
}

- (void) setOriginalViewValue: (NSObject *) value forKey: (NSValue *) key {
    NSMutableDictionary *tr8nViewData = objc_getAssociatedObject(self, &Tr8nViewData);
    if (tr8nViewData == nil) {
        tr8nViewData = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &Tr8nViewData, tr8nViewData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [tr8nViewData setObject:value forKey:key];
}

- (NSString *) translationKeyForKey: (NSValue *) key {
    NSMutableDictionary *tr8nKeyData = objc_getAssociatedObject(self, &Tr8nKeyData);
    return [tr8nKeyData objectForKey:key];
}

- (void) setTranslationKey: (NSString *) value forKey: (NSValue *) key {
    NSMutableDictionary *tr8nKeyData = objc_getAssociatedObject(self, &Tr8nKeyData);
    if (tr8nKeyData == nil) {
        tr8nKeyData = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &Tr8nKeyData, tr8nKeyData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [tr8nKeyData setObject:value forKey:key];
}

- (NSDictionary *) dataForView: (UIView *) view  withDefault: (NSDictionary *(^)()) defaultData {
    NSValue *key = [self viewHashKey:view];
    
    NSDictionary *data = [self originalViewValueForKey:key];
    if (data == nil) {
        data = defaultData();
        [self setOriginalViewValue:data forKey:key];
    }
    return data;
}

- (NSDictionary *) dataForObject: (NSObject *) object  withDefault: (NSDictionary *(^)()) defaultData {
    NSValue *key = [NSValue valueWithNonretainedObject:object];
    
    NSDictionary *data = [self originalViewValueForKey:key];
    if (data == nil) {
        data = defaultData();
        [self setOriginalViewValue:data forKey:key];
    }
    return data;
}

- (void) translateLabel: (UILabel *) label {
    NSDictionary *data = [self dataForView:label withDefault:^NSDictionary *{
        return @{
            @"text": label.text,
        };
    }];
    
    if ([[data objectForKey:@"text"] length] > 0) {
        [self setTranslationKey:Tr8nTranslationKey([data objectForKey:@"text"], @"") forKey:[self viewHashKey:label]];
        label.text = Tr8nLocalizedString([data objectForKey:@"text"]);
    }
    
    [self addInAppTranslatorGestureRecognizer: label];
}

- (void) translateButton: (UIButton *) button {
    NSDictionary *data = [self dataForView:button withDefault:^NSDictionary *{
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        if ([button titleForState:UIControlStateNormal]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_normal"];
        if ([button titleForState:UIControlStateHighlighted]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_highlighted"];
        if ([button titleForState:UIControlStateDisabled]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_disabled"];
        if ([button titleForState:UIControlStateSelected]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_selected"];
        if ([button titleForState:UIControlStateApplication]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_application"];
        if ([button titleForState:UIControlStateReserved]) [data setObject:[button titleForState:UIControlStateNormal] forKey:@"text_reserved"];
        return data;
    }];
    
    if ([data objectForKey:@"text_normal"]) [button setTitle:Tr8nLocalizedString([data objectForKey:@"text_normal"]) forState:UIControlStateNormal];
    if ([data objectForKey:@"text_highlighted"]) [button setTitle:Tr8nLocalizedString([data objectForKey:@"text_normal"]) forState:UIControlStateHighlighted];
    if ([data objectForKey:@"text_disabled"]) [button setTitle:Tr8nLocalizedString([data objectForKey:@"text_normal"]) forState:UIControlStateDisabled];
    if ([data objectForKey:@"text_selected"]) [button setTitle:Tr8nLocalizedString([data objectForKey:@"text_normal"]) forState:UIControlStateSelected];
    if ([data objectForKey:@"text_application"]) [button setTitle:Tr8nLocalizedString([data objectForKey:@"text_normal"]) forState:UIControlStateApplication];
    if ([data objectForKey:@"text_reserved"]) [button setTitle:Tr8nLocalizedString([data objectForKey:@"text_normal"]) forState:UIControlStateReserved];
    
    [self addInAppTranslatorGestureRecognizer: button];
}

- (void) translateTextField: (UITextField *) textField {
    NSDictionary *data = [self dataForView:textField withDefault:^NSDictionary *{
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        if (textField.placeholder) [data setObject:textField.placeholder forKey:@"placeholder"];
        return data;
    }];
    
    if ([[data objectForKey:@"placeholder"] length] > 0) {
        textField.placeholder = Tr8nLocalizedString([data objectForKey:@"placeholder"]);
    }
    
    [self addInAppTranslatorGestureRecognizer: textField];
}

- (void) translateBarButtonItem: (UIBarButtonItem *) barButtonItem {
    NSDictionary *data = [self dataForObject:barButtonItem withDefault:^NSDictionary *{
        return @{
                 @"title": barButtonItem.title
        };
    }];
    
    if ([[data objectForKey:@"title"] length] > 0) {
        barButtonItem.title = [Tr8n translate:[data objectForKey:@"title"]];
    }
}

- (void) translateNavigationItem: (UINavigationItem *) navigationItem {
    NSDictionary *data = [self dataForObject:navigationItem withDefault:^NSDictionary *{
        return @{
                 @"title": navigationItem.title
        };
    }];
    
    if ([[data objectForKey:@"title"] length] > 0) {
        navigationItem.title = [Tr8n translate:[data objectForKey:@"title"]];
    }
}

- (void) translateSearchBar: (UISearchBar *) searchBar {
    NSDictionary *data = [self dataForObject:searchBar withDefault:^NSDictionary *{
        return @{
                 @"text": searchBar.text,
                 @"placeholder": searchBar.placeholder,
                 @"prompt": searchBar.prompt
        };
    }];
    
    if ([[data objectForKey:@"text"] length] > 0) {
        searchBar.text = [Tr8n translate:[data objectForKey:@"text"]];
    }
    
    if ([[data objectForKey:@"placeholder"] length] > 0) {
        searchBar.placeholder = [Tr8n translate:[data objectForKey:@"placeholder"]];
    }
    
    if ([[data objectForKey:@"prompt"] length] > 0) {
        searchBar.prompt = [Tr8n translate:[data objectForKey:@"prompt"]];
    }
}

- (void) translateView: (UIView *) view {
    if (view == nil) return;
    
    // NSLog(@"Translating: %@", NSStringFromClass([view class]));

    if ([view isKindOfClass:UILabel.class])
        [self translateLabel:(UILabel *) view];
    else if ([view isKindOfClass:UIButton.class])
        [self translateButton:(UIButton *) view];
    else if ([view isKindOfClass:UITextField.class])
        [self translateTextField:(UITextField *) view];
    else if ([view isKindOfClass:UIBarButtonItem.class])
        [self translateBarButtonItem:(UIBarButtonItem *) view];
    else if ([view isKindOfClass:UINavigationItem.class])
        [self translateNavigationItem:(UINavigationItem *) view];
    else if ([view isKindOfClass:UISearchBar.class])
        [self translateSearchBar:(UISearchBar *) view];
    else if ([view isKindOfClass:UITableView.class]) {
        UITableView *tableView = (UITableView *) view;
        for (int i=0; i<[tableView numberOfSections]; i++) {
            for (int j=0; j<[tableView numberOfRowsInSection:i]; j++) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
                for (UIView *view in cell.subviews) {
                    [self translateView:view];
                }
            }
        }
    } else {
        for (UIView *subview in view.subviews) {
            [self translateView:subview];
        }
    }
}

- (void) translateView: (UIView *) view withLabel: (NSString *) label description: (NSString *) description tokens: (NSDictionary *) tokens options: (NSDictionary *) options {

    if (view == nil) return;
    
    // NSLog(@"Translating: %@", NSStringFromClass([view class]));

    NSString *text = nil;
    NSAttributedString *attributedText = nil;
    
    [self setTranslationKey:Tr8nTranslationKey(label, description) forKey:[self viewHashKey:view]];
    
    if ([label rangeOfString:@"["].location != NSNotFound) {
        attributedText = Tr8nLocalizedAttributedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options);
    } else {
        text = Tr8nLocalizedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options);
    }
        
    if ([view isKindOfClass:UILabel.class]) {
        UILabel *lbl = (UILabel *) view;
        if (attributedText) lbl.attributedText = attributedText;
        if (text) lbl.text = text;
    } else if ([view isKindOfClass: UIButton.class]) {
        UIButton *btn = (UIButton *) view;
        if (attributedText) [btn setAttributedTitle:attributedText forState:UIControlStateNormal];
        if (text) [btn setTitle:text forState:UIControlStateNormal];
    } else if ([view isKindOfClass: UITextField.class]) {
        UITextField *fld = (UITextField *) view;
        if (attributedText) [fld setAttributedPlaceholder:attributedText];
        if (text) [fld setPlaceholder:text];
    }
    
    [self addInAppTranslatorGestureRecognizer: view];
}

- (void) addInAppTranslatorGestureRecognizer:(UIView *) view {
    for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]])
            [view removeGestureRecognizer:recognizer];
    }
    
    if (![Tr8n configuration].inContextTranslatorEnabled) return;
    
    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePressAndHold:)];
    view.userInteractionEnabled = YES;
    [view addGestureRecognizer:gestureRecognizer];
}

- (void) handlePressAndHold:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSValue *fieldKey = [self viewHashKey:recognizer.view];
        NSDictionary *originalData = [self originalViewValueForKey: fieldKey];
        NSString *translationKey = nil;

        if (!originalData)
            translationKey = [self translationKeyForKey: fieldKey];
        else if ([recognizer.view isKindOfClass: UILabel.class]) {
            translationKey = [Tr8nTranslationKey generateKeyForLabel:[originalData valueForKey:@"text"]];
        } else if ([recognizer.view isKindOfClass: UIButton.class]) {
            translationKey = [Tr8nTranslationKey generateKeyForLabel:[originalData valueForKey:@"text_normal"]];
        } else if ([recognizer.view isKindOfClass: UITextField.class]) {
            translationKey = [Tr8nTranslationKey generateKeyForLabel:[originalData valueForKey:@"placeholder"]];
        }
        
        if (translationKey)
            [Tr8nTranslatorViewController translateFromController: self withOptions:@{@"translation_key": translationKey}];
    }
}

@end
