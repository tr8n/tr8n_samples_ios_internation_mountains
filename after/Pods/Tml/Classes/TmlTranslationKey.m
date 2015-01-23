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

#import "TmlTranslationKey.h"
#import "TmlTranslation.h"
#import "TmlTranslation.h"
#import "TmlDataTokenizer.h"
#import "TmlDecorationTokenizer.h"
#import "TmlDataToken.h"
#import "TmlAttributedDecorationTokenizer.h"
#import "TmlHtmlDecorationTokenizer.h"
#import "Tml.h"

@implementation TmlTranslationKey
@synthesize application, key, label, description, locale, level, translations;

+ (NSString *) generateKeyForLabel: (NSString *) label {
    return [self generateKeyForLabel:label andDescription:@""];
}

+ (NSString *) generateKeyForLabel: (NSString *) label andDescription: (NSString *) description {
    if (description == nil) description = @"";
    return [TmlConfiguration md5:[NSString stringWithFormat:@"%@;;;%@", label, description]];
}

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"application"])
        self.application = [attributes objectForKey:@"application"];

    self.label = [attributes objectForKey:@"label"];
    self.description = [attributes objectForKey:@"description"];
    
    if ([attributes objectForKey:@"key"]) {
        self.key = [attributes objectForKey:@"key"];
    } else {
        self.key = [self.class generateKeyForLabel:self.label andDescription:self.description];
    }
    
    self.locale = [attributes objectForKey:@"locale"];
    if (self.locale == nil)
        self.locale = [[[Tml sharedInstance] defaultLanguage] locale];
    
    self.level = [attributes objectForKey:@"level"];
    self.translations = @[];
}

- (BOOL) hasTranslations {
    return [self.translations count] > 0;
}

- (NSDictionary *) toDictionary {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:label forKey:@"label"];
    if (locale!= nil && [locale length] > 0)
        [data setObject:locale forKey:@"locale"];
    if (description!= nil && [description length] > 0)
        [data setObject:description forKey:@"description"];
    if (level!=nil)
        [data setObject:level forKey:@"level"];
    return data;
}

- (TmlTranslation *) findFirstAcceptableTranslationForTokens: (NSDictionary *) tokens {
    // Get out right away
    if ([self.translations count] == 0)
        return nil;

    // Most common and fastest way to get out
    if ([self.translations count] == 1) {
        TmlTranslation *t = (TmlTranslation *) [self.translations objectAtIndex:0];
        if (t.context == nil) return t;
    }
    
    for (TmlTranslation *t in self.translations) {
        if ([t isValidTranslationForTokens:tokens])
            return t;
    }
    
//    TmlDebug(@"No acceptable ranslations found");
    return nil;
}

- (NSObject *) translateToLanguage: (TmlLanguage *) language {
    return [self translateToLanguage:language withTokens:@{}];
}

- (NSObject *) translateToLanguage: (TmlLanguage *) language withTokens: (NSDictionary *) tokens {
    return [self translateToLanguage:language withTokens:tokens andOptions:@{}];
}

- (NSObject *) translateToLanguage: (TmlLanguage *) language withTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    if ([language.locale isEqualToString:self.locale]) {
        return [self substituteTokensInLabel:self.label withTokens:tokens forLanguage:language andOptions:options];
    }
    
    TmlTranslation *translation = [self findFirstAcceptableTranslationForTokens: tokens];
    
    if (translation) {
        return [self substituteTokensInLabel:translation.label withTokens:tokens forLanguage:language andOptions:options];
    }
    
    language = (TmlLanguage *)[self.application languageForLocale:self.locale];
    return [self substituteTokensInLabel:self.label withTokens:tokens forLanguage:language andOptions:options];
}

- (NSArray *) dataTokenNames {
    TmlDataTokenizer *tokenizer = [[TmlDataTokenizer alloc] initWithLabel:self.label];
    return [tokenizer tokenNames];
}

- (NSArray *) decorationTokenNames {
    TmlDecorationTokenizer *tokenizer = [[TmlDecorationTokenizer alloc] initWithLabel:self.label];
    return [tokenizer tokenNames];
}

- (NSObject *) substituteTokensInLabel: (NSString *) translatedLabel withTokens: (NSDictionary *) tokens forLanguage: (TmlLanguage *) language andOptions: (NSDictionary *) options {
    if ([translatedLabel rangeOfString:@"{"].length > 0) {
        TmlDataTokenizer *tokenizer = [[TmlDataTokenizer alloc] initWithLabel:translatedLabel andAllowedTokenNames:[self dataTokenNames]];
        translatedLabel = [tokenizer substituteTokensInLabelUsingData:tokens forLanguage:language withOptions:options];
    }

    if ([[options objectForKey:@"tokenizer"] isEqual: @"attributed"]) {
        if ([translatedLabel rangeOfString:@"["].length > 0) {
            TmlDecorationTokenizer *tokenizer = [[TmlAttributedDecorationTokenizer alloc] initWithLabel:translatedLabel andAllowedTokenNames:[self decorationTokenNames]];
            return [tokenizer substituteTokensInLabelUsingData:tokens withOptions:options];
        }
        return [[NSAttributedString alloc] initWithString:translatedLabel];
    }
    
    if ([translatedLabel rangeOfString:@"["].length > 0) {
        TmlDecorationTokenizer *tokenizer = [[TmlHtmlDecorationTokenizer alloc] initWithLabel:translatedLabel andAllowedTokenNames:[self decorationTokenNames]];
        return [tokenizer substituteTokensInLabelUsingData:tokens withOptions:options];
    }
    
    return translatedLabel;
}

- (NSString *) description {
    return self.label;
}

@end
