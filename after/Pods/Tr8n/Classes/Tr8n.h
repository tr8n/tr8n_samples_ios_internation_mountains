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


#define TR8N_DEBUG 1

#import <Foundation/Foundation.h>
#import "Tr8nApplication.h"
#import "Tr8nLanguage.h"
#import "Tr8nSource.h"
#import "Tr8nConfiguration.h"
#import "Tr8nCache.h"

#define Tr8nLanguageDidChangeNotification @"Tr8nLanguageDidChangeNotification"
#define Tr8nTranslationsLoadedNotification @"Tr8nTranslationsLoadedNotification"

@protocol Tr8nDelegate;

@interface Tr8n : NSObject

// Holds Tr8n configuration settings
@property(nonatomic, strong) Tr8nConfiguration *configuration;

// Holds reference to the cache object
@property(nonatomic, strong) Tr8nCache *cache;

// Holds the application information
@property(nonatomic, strong) Tr8nApplication *currentApplication;

// Holds default language of the application
@property(nonatomic, strong) Tr8nLanguage *defaultLanguage;

// Holds current language, per user selection
@property(nonatomic, strong) Tr8nLanguage *currentLanguage;

// Holds the current source key
@property(nonatomic, strong) NSString *currentSource;

// Holds the current user object
@property(nonatomic, strong) NSObject *currentUser;

// Holds block options
@property(nonatomic, strong) NSMutableArray *blockOptions;

// Tr8n delegate
@property(nonatomic, assign) id <Tr8nDelegate> delegate;

// Initializes Tr8n application with key only - for production mode
+ (void) initWithKey: (NSString *) key;

// Initializes Tr8n application with key and secret - for registration mode
+ (void) initWithKey: (NSString *) key secret: (NSString *) secret;

// Initializes Tr8n application with host, key and secret
+ (void) initWithKey: (NSString *) key secret: (NSString *) secret host: (NSString *) host;

// Tr8n singleton
+ (Tr8n*) sharedInstance;

// Configuration methods
+ (void) configure:(void (^)(Tr8nConfiguration *config)) changes;

// Returns configuration
+ (Tr8nConfiguration *) configuration;

// Returns cache
+ (Tr8nCache *) cache;

/**
 * HTML Translation Methods
 */
+ (NSString *) translate:(NSString *) label;

+ (NSString *) translate:(NSString *) label withDescription:(NSString *) description;

+ (NSString *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens;

+ (NSString *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options;

+ (NSString *) translate:(NSString *) label withTokens: (NSDictionary *) tokens;

+ (NSString *) translate:(NSString *) label withTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options;

+ (NSString *) translate:(NSString *) label withOptions: (NSDictionary *) options;

/**
 * Attributed String Translation Methods
 */
+ (NSAttributedString *) translateAttributedString:(NSString *) label;

+ (NSAttributedString *) translateAttributedString:(NSString *) label withDescription:(NSString *) description;

+ (NSAttributedString *) translateAttributedString:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens;

+ (NSAttributedString *) translateAttributedString:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options;

+ (NSAttributedString *) translateAttributedString:(NSString *) label withTokens: (NSDictionary *) tokens;

+ (NSAttributedString *) translateAttributedString:(NSString *) label withTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options;

+ (NSAttributedString *) translateAttributedString:(NSString *) label withOptions: (NSDictionary *) options;

+ (NSString *) localizeDate:(NSDate *) date withFormat:(NSString *) format andDescription: (NSString *) description;

/************************************************************************************
 ** Block Options
 ************************************************************************************/

+ (void) beginBlockWithOptions:(NSDictionary *) options;

+ (NSObject *) blockOptionForKey: (NSString *) key;

+ (void) endBlockWithOptions;

/************************************************************************************
 Class Methods
 ************************************************************************************/

+ (Tr8nApplication *) currentApplication;

+ (Tr8nLanguage *) defaultLanguage;

+ (Tr8nLanguage *) currentLanguage;

+ (void) changeLocale: (NSString *) locale success: (void (^)()) success failure: (void (^)(NSError *error)) failure;

+ (void) reloadSource: (NSString *) sourceKey;

+ (void) reloadTranslations;

+ (void) submitMissingTranslationKeys;

+ (NSString *) pluralize:(NSString *) word;

+ (NSString *) pluralize:(NSString *) word inLanguage: (Tr8nLanguage *) language;

+ (NSString *) singularize:(NSString *) word;

+ (NSString *) singularize:(NSString *) word inLanguage: (Tr8nLanguage *) language;

//+ (NSString *) ordinalize:(NSNumber *) num;

@end


/************************************************************************************
 Tr8n Delegate
 ************************************************************************************/

@protocol Tr8nDelegate <NSObject>

- (void) tr8nDidLoadTranslations;

@end

/************************************************************************************
 Default Tr8n Macros
 ************************************************************************************/

#define Tr8nTranslationKey(label, description) \
    [Tr8nTranslationKey generateKeyForLabel: label andDescription: description]

#define Tr8nLocalizedString(label) \
    [Tr8n translate: label withDescription: nil andTokens: @{} andOptions: @{}]

#define Tr8nLocalizedStringWithDescription(label, description) \
    [Tr8n translate: label withDescription: description andTokens: @{} andOptions: @{}]

#define Tr8nLocalizedStringWithDescriptionAndTokens(label, description, tokens) \
    [Tr8n translate: label withDescription: description andTokens: tokens andOptions: @{}]

#define Tr8nLocalizedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options) \
    [Tr8n translate: label withDescription: description andTokens: tokens andOptions: options]

#define Tr8nLocalizedStringWithTokens(label, tokens) \
    [Tr8n translate: label withDescription: nil andTokens: tokens andOptions: nil]

#define Tr8nLocalizedStringWithTokensAndOptions(label, tokens, options) \
    [Tr8n translate: label withDescription: nil andTokens: tokens andOptions: options]

#define Tr8nLocalizedStringWithOptions(label, options) \
    [Tr8n translate: label withDescription: nil andTokens: @{} andOptions: options]

#define Tr8nLocalizedStringWithDescriptionAndOptions(label, description, options) \
    [Tr8n translate: label withDescription: description andTokens: @{} andOptions: options]

#define Tr8nLocalizedAttributedString(label) \
    [Tr8n translateAttributedString: label withDescription: nil andTokens: @{} andOptions: @{}]

#define Tr8nLocalizedAttributedStringWithDescription(label, description) \
    [Tr8n translateAttributedString: label withDescription: description andTokens: @{} andOptions: @{}]

#define Tr8nLocalizedAttributedStringWithDescriptionAndTokens(label, description, tokens) \
    [Tr8n translateAttributedString: label withDescription: description andTokens: tokens andOptions: @{}]

#define Tr8nLocalizedAttributedStringWithDescriptionAndTokensAndOptions(label, description, tokens, options) \
    [Tr8n translateAttributedString: label withDescription: description andTokens: tokens andOptions: options]

#define Tr8nLocalizedAttributedStringWithTokens(label, tokens) \
    [Tr8n translateAttributedString: label withDescription: nil andTokens: tokens andOptions: nil]

#define Tr8nLocalizedAttributedStringWithTokensAndOptions(label, tokens, options) \
    [Tr8n translateAttributedString: label withDescription: nil andTokens: tokens andOptions: options]

#define Tr8nLocalizedAttributedStringWithOptions(label, options) \
    [Tr8n translateAttributedString: label withDescription: nil andTokens: @{} andOptions: options]

#define Tr8nBeginSource(name) \
    [Tr8n beginBlockWithOptions: @{@"source": name}];

#define Tr8nEndSource \
    [Tr8n endBlockWithOptions];

#define Tr8nBeginBlockWithOptions(options) \
    [Tr8n beginBlockWithOptions:options];

#define Tr8nEndBlockWithOptions \
    [Tr8n endBlockWithOptions];

#define Tr8nLocalizedDateWithFormat(date, format) \
    [Tr8n localizeDate: date withFormat: format andDescription: nil];

#define Tr8nLocalizedDateWithFormatAndDescription(date, format, description) \
[Tr8n localizeDate: date withFormat: format andDescription: description];

#define Tr8nLocalizedDateWithFormatKey(date, formatKey) \
    [Tr8n localizeDate: date withFormatKey: formatKey andDescription: nil];

#define Tr8nLocalizedDateWithFormatKeyAndDescription(date, formatKey, description) \
    [Tr8n localizeDate: date withFormatKey: formatKey andDescription: description];

/************************************************************************************
 Overload the defeault localization macros
 ************************************************************************************/

#undef NSLocalizedString
#define NSLocalizedString(key, comment) \
    [Tr8n translate: key withDescription: comment]

#undef NSLocalizedStringFromTable
#define NSLocalizedStringFromTable(key, tbl, comment) \
    [Tr8n translate: key withDescription: comment]

#undef NSLocalizedStringFromTableInBundle
#define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) \
    [Tr8n translate: key withDescription: comment]

#undef NSLocalizedStringWithDefaultValue
#define NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) \
    [Tr8n translate: key withDescription: comment]

