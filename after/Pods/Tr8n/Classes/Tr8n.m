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


#import "Tr8n.h"
#import <CommonCrypto/CommonDigest.h>
#import "Tr8nTranslationKey.h"
#import "Tr8nTranslation.h"
#import "Tr8nCache.h"
#import "Tr8nLanguageCase.h"
#import "Tr8nDataToken.h"

#define kTr8nServiceHost @"https://api.translationexchange.com"

/************************************************************************************
 ** Implementation
 ************************************************************************************/

@interface Tr8n (Private)
- (void) beginBlockWithOptions:(NSDictionary *) options;
- (NSDictionary *) currentBlockOptions;
- (NSObject *) blockOptionForKey: (NSString *) key;
- (void) endBlockWithOptions;

- (void) changeLocale: (NSString *) locale;

//- (NSString *) languageCachePath;
//- (NSString *) translationCachePath;
//- (void) saveTranslationsToCache:(NSData *) data;
//- (void) loadTranslationsFromCache;
@end

@implementation Tr8n

@synthesize configuration, cache;
@synthesize currentApplication, defaultLanguage, currentLanguage, currentSource, currentUser, delegate;
@synthesize blockOptions;

//@synthesize translationKeys, missingTranslationKeys, timer;
//@synthesize debug, production;

+ (Tr8n *)sharedInstance {
    static Tr8n *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[Tr8n alloc] init];
    });
    
    return _sharedInstance;
}

+ (NSString *) translate:(NSString *) label {
    return [self translate:label withDescription:@"" andTokens:@{} andOptions:@{}];
}

+ (NSString *) translate:(NSString *) label withDescription:(NSString *) description {
    return [self translate:label withDescription:description andTokens:@{} andOptions:@{}];
}

+ (NSString *) translate:(NSString *) label withTokens: (NSDictionary *) tokens {
    return [self translate:label withDescription:@"" andTokens:tokens andOptions:@{}];
}

+ (NSString *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens {
    return [self translate:label withDescription:description andTokens:tokens andOptions:@{}];
}

+ (NSString *) translate:(NSString *) label withTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    return [self translate:label withDescription:@"" andTokens:tokens andOptions:options];
}

+ (NSString *) translate:(NSString *) label withOptions: (NSDictionary *) options {
    return [self translate:label withDescription:@"" andTokens:@{} andOptions:options];
}

+ (NSString *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    NSMutableDictionary *opts = [NSMutableDictionary dictionaryWithDictionary:options];
    [opts setObject:@"html" forKey:@"tokenizer"];
    return (NSString *) [[self sharedInstance] translate:label withDescription:description andTokens:tokens andOptions:opts];
}

+ (NSAttributedString *) translateAttributedString:(NSString *) label {
    return [self translateAttributedString:label withDescription:@"" andTokens:@{} andOptions:@{}];
}

+ (NSAttributedString *) translateAttributedString:(NSString *) label withDescription:(NSString *) description {
    return [self translateAttributedString:label withDescription:description andTokens:@{} andOptions:@{}];
}

+ (NSAttributedString *) translateAttributedString:(NSString *) label withTokens: (NSDictionary *) tokens {
    return [self translateAttributedString:label withDescription:@"" andTokens:tokens andOptions:@{}];
}

+ (NSAttributedString *) translateAttributedString:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens {
    return [self translateAttributedString:label withDescription:description andTokens:tokens andOptions:@{}];
}

+ (NSAttributedString *) translateAttributedString:(NSString *) label withTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    return [self translateAttributedString:label withDescription:@"" andTokens:tokens andOptions:@{}];
}

+ (NSAttributedString *) translateAttributedString:(NSString *) label withOptions: (NSDictionary *) options {
    return [self translateAttributedString:label withDescription:@"" andTokens:@{} andOptions:@{}];
}

+ (NSAttributedString *) translateAttributedString:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    NSMutableDictionary *opts = [NSMutableDictionary dictionaryWithDictionary:options];
    [opts setObject:@"attributed" forKey:@"tokenizer"];
    return (NSAttributedString *) [[self sharedInstance] translate:label withDescription:description andTokens:tokens andOptions:opts];
}

+ (NSString *) localizeDate:(NSDate *) date withFormat:(NSString *) format andDescription: (NSString *) description {
    return [[self sharedInstance] localizeDate: date withFormat: format andDescription: description];
}

+ (NSString *) localizeDate:(NSDate *) date withFormatKey:(NSString *) formatKey andDescription: (NSString *) description {
    return [[self sharedInstance] localizeDate: date withFormatKey: formatKey andDescription: description];
}

+ (NSString *) localizeDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    return [[self sharedInstance] localizeDate: date withTokenizedFormat: tokenizedFormat andDescription: description];
}

+ (NSAttributedString *) localizeAttributedDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    return [[self sharedInstance] localizeAttributedDate: date withTokenizedFormat: tokenizedFormat andDescription: description];
}

/************************************************************************************
 ** Initialization
 ************************************************************************************/

/**
 * Initialize Tr8nProxy object with locale
 */

- (id) init {
    if (self = [super init]) {
        self.configuration = [[Tr8nConfiguration alloc] init];
        self.cache = [[Tr8nCache alloc] init];
    }
    return self;
}

+ (void) initWithKey: (NSString *) key {
    [self initWithKey:key secret:nil];
}

+ (void) initWithKey: (NSString *) key secret: (NSString *) secret {
    [self initWithKey:key secret:secret host: kTr8nServiceHost];
}

+ (void) initWithKey: (NSString *) key secret: (NSString *) secret host: (NSString *) host {
    [[self sharedInstance] updateWithHost:host key:key secret:secret];
}

- (void) updateWithHost: (NSString *) host key: (NSString *) key secret: (NSString *) secret {
    self.currentApplication = [[Tr8nApplication alloc] initWithHost:host key:key secret:secret];
    self.defaultLanguage = (Tr8nLanguage *) [self.currentApplication languageForLocale: configuration.defaultLocale];
    self.currentLanguage = (Tr8nLanguage *) [self.currentApplication languageForLocale: configuration.currentLocale];

    [self.currentApplication loadTranslationsForLocale:self.currentLanguage.locale withOptions:@{} success:^{
    } failure:^(NSError *error) {
    }];
}

/************************************************************************************
 ** Configuration
 ************************************************************************************/

+ (void) configure:(void (^)(Tr8nConfiguration *config)) changes {
    changes([self sharedInstance].configuration);
}

+ (Tr8nConfiguration *) configuration {
    return [[self sharedInstance] configuration];
}

+ (Tr8nCache *) cache {
    return [[self sharedInstance] cache];
}

/************************************************************************************
 ** Block Options
 ************************************************************************************/

+ (void) beginBlockWithOptions:(NSDictionary *) options {
    [[self sharedInstance] beginBlockWithOptions:options];
}

+ (NSObject *) blockOptionForKey: (NSString *) key {
    return [[self sharedInstance] blockOptionForKey: key];
}

+ (void) endBlockWithOptions {
    [[self sharedInstance] endBlockWithOptions];
}

- (void) beginBlockWithOptions:(NSDictionary *) options {
    if (self.blockOptions == nil)
        self.blockOptions = [NSMutableArray array];
    
    [self.blockOptions insertObject:options atIndex:0];
}

- (NSDictionary *) currentBlockOptions {
    if (self.blockOptions == nil)
        self.blockOptions = [NSMutableArray array];
    
    if ([self.blockOptions count] == 0)
        return [NSDictionary dictionary];

    return [self.blockOptions objectAtIndex:0];
}

- (NSObject *) blockOptionForKey: (NSString *) key {
    return [[self currentBlockOptions] objectForKey:key];
}

- (void) endBlockWithOptions {
    if (self.blockOptions == nil)
        return;
    
    if ([self.blockOptions count] == 0)
        return;
    
    [self.blockOptions removeObjectAtIndex:0];
}

/************************************************************************************
 ** Class Methods
 ************************************************************************************/

+ (Tr8nApplication *) currentApplication {
    return [[self sharedInstance] currentApplication];
}

+ (Tr8nLanguage *) defaultLanguage {
    return [[self sharedInstance] defaultLanguage];
}

+ (Tr8nLanguage *) currentLanguage {
    return [[self sharedInstance] currentLanguage];
}

+ (void) changeLocale: (NSString *) locale success: (void (^)()) success failure: (void (^)(NSError *error)) failure {
    [[self sharedInstance] changeLocale:locale success:success failure:failure];
}

- (void) changeLocale: (NSString *) locale success: (void (^)()) success failure: (void (^)(NSError *error)) failure {
    NSString *previousLocale = self.configuration.currentLocale;
    self.configuration.currentLocale = locale;
    [cache backupCacheForLocale: locale];
    
    Tr8nLanguage *previousLanguage = self.currentLanguage;
    self.currentLanguage = (Tr8nLanguage *) [self.currentApplication languageForLocale: locale reload:YES];
    
    [self.currentApplication resetTranslations];
    [self.currentApplication loadTranslationsForLocale:self.currentLanguage.locale withOptions:@{@"reload": @YES} success:^{
		[[NSNotificationCenter defaultCenter] postNotificationName: Tr8nLanguageDidChangeNotification object: self.currentLanguage];
        
        if ([self.delegate respondsToSelector:@selector(tr8nDidLoadTranslations)]) {
            [self.delegate tr8nDidLoadTranslations];
        }
        
        success();
        
    } failure:^(NSError *error) {
        // rollback to the previous locale
        self.configuration.currentLocale = previousLocale;
        self.currentLanguage = previousLanguage;
        [cache restoreCacheBackupForLocale:locale];
        failure(error);
    }];
}

+ (void) reloadTranslations {
    [[self sharedInstance] reloadTranslations];
}

- (void) reloadTranslations {
    [cache backupCacheForLocale: self.currentLanguage.locale];

    [self.currentApplication resetTranslations];
    [self.currentApplication loadTranslationsForLocale:self.currentLanguage.locale withOptions:@{@"reload": @YES} success:^{

        if ([self.delegate respondsToSelector:@selector(tr8nDidLoadTranslations)]) {
            [self.delegate tr8nDidLoadTranslations];
        }
    } failure:^(NSError *error) {
        [cache restoreCacheBackupForLocale: self.currentLanguage.locale];
    }];
}

+ (void) submitMissingTranslationKeys {
    [[Tr8n sharedInstance].currentApplication submitMissingTranslationKeys];
}

+ (void) reloadSource: (NSString *) sourceKey {
    [[Tr8n sharedInstance].currentApplication reloadSource: sourceKey];
}

+ (NSString *) pluralize:(NSString *) word {
    return [self pluralize:word inLanguage:[self sharedInstance].defaultLanguage];
}

+ (NSString *) pluralize:(NSString *) word inLanguage: (Tr8nLanguage *) language {
    Tr8nLanguageCase *lcase = (Tr8nLanguageCase *) [language languageCaseByKeyword: @"plural"];
    if (lcase == nil)
        return word;
    return [lcase apply:word];
}

+ (NSString *) singularize:(NSString *) word {
    return [self pluralize:word inLanguage:[self sharedInstance].defaultLanguage];
}

+ (NSString *) singularize:(NSString *) word inLanguage: (Tr8nLanguage *) language {
    Tr8nLanguageCase *lcase = (Tr8nLanguageCase *) [language languageCaseByKeyword: @"singular"];
    if (lcase == nil)
        return word;
    return [lcase apply:word];
}


/************************************************************************************
 ** Translation Methods
 ************************************************************************************/

- (NSString *) callerClass {
    NSArray *stack = [NSThread callStackSymbols];
    NSString *caller = [[[stack objectAtIndex:2] componentsSeparatedByString:@"["] objectAtIndex:1];
    caller = [[caller componentsSeparatedByString:@" "] objectAtIndex:0];
    NSLog(@"caller: %@", stack);
    return caller;
}

- (NSObject *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    // if Tr8n is used in a disconnected mode or has not been initialized, fallback onto English US
    if (self.currentLanguage == nil) {
        self.defaultLanguage = [Tr8nLanguage defaultLanguage];
        self.currentLanguage = self.defaultLanguage;
    }
    return [self.currentLanguage translate:label withDescription:description andTokens:tokens andOptions:options];
}


/************************************************************************************
 ** Localization Methods
 ************************************************************************************/

- (NSDictionary *) tokenValuesForDate: (NSDate *) date fromTokenizedFormat:(NSString *) tokenizedFormat {
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    
    NSArray *matches = [[Tr8nDataToken expression] matchesInString: tokenizedFormat options: 0 range: NSMakeRange(0, [tokenizedFormat length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *tokenName = [tokenizedFormat substringWithRange:[match range]];
        
        if (tokenName) {
            [tokens setObject:[[self configuration] dateValueForToken: tokenName inDate:date] forKey:[tokenName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]]];
        }
    }
    
    return tokens;
}

// {months_padded}/{days_padded}/{years} at {hours}:{minutes}
- (NSString *) localizeDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    
    NSLog(@"Tokenized date string: %@", tokenizedFormat);
    NSLog(@"Tokenized date string: %@", [tokens description]);
    
    return Tr8nLocalizedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
}

// {days} {month_name::gen} at [bold: {hours}:{minutes}] {am_pm}
- (NSAttributedString *) localizeAttributedDate:(NSDate *) date withTokenizedFormat:(NSString *) tokenizedFormat andDescription: (NSString *) description {
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    
    NSLog(@"Tokenized date string: %@", tokenizedFormat);
    NSLog(@"Tokenized date string: %@", [tokens description]);
    
    return Tr8nLocalizedAttributedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
}

// default_format
- (NSString *) localizeDate:(NSDate *) date withFormatKey:(NSString *) formatKey andDescription: (NSString *) description {
    NSString *format = [[self configuration] customDateFormatForKey: formatKey];
    if (!format) return formatKey;
    return [self localizeDate: date withFormat:format andDescription: description];
}

// MM/dd/yyyy at h:m
- (NSString *) localizeDate:(NSDate *) date withFormat:(NSString *) format andDescription: (NSString *) description {
    NSError *error = NULL;
    NSRegularExpression *expression = [NSRegularExpression
                                  regularExpressionWithPattern: @"[\\w]*"
                                  options: NSRegularExpressionCaseInsensitive
                                  error: &error];

//    NSLog(@"Parsing date format: %@", format);
    NSString *tokenizedFormat = format;
    
    NSArray *matches = [expression matchesInString: format options: 0 range: NSMakeRange(0, [format length])];
    NSMutableArray *elements = [NSMutableArray array];
    
    int index = 0;
    for (NSTextCheckingResult *match in matches) {
        NSString *element = [format substringWithRange:[match range]];
        [elements addObject:element];
        NSString *placeholder = [NSString stringWithFormat: @"{%d}", index++];
        tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:element withString: placeholder];
    }

//    NSLog(@"Tokenized date string: %@", tokenizedFormat);

    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    
    for (index=0; index<[elements count]; index++) {
        NSString *element = [elements objectAtIndex:index];
        NSString *tokenName = [[self configuration] dateTokenNameForKey: element];
        NSString *placeholder = [NSString stringWithFormat: @"{%d}", index];
        
        if (tokenName) {
            tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:placeholder withString:tokenName];
            [tokens setObject:[[self configuration] dateValueForToken: tokenName inDate:date] forKey:[tokenName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]]];
        } else
            tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:placeholder withString:element];
    }
    
    NSLog(@"Tokenized date string: %@", tokenizedFormat);
    NSLog(@"Tokenized date string: %@", [tokens description]);

    return Tr8nLocalizedStringWithDescriptionAndTokens(tokenizedFormat, description, tokens);
}


@end
