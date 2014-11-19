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

#import "Tr8nLanguage.h"
#import "Tr8nApplication.h"
#import "Tr8nLanguageCase.h"
#import "Tr8nLanguageContext.h"
#import "Tr8nBase.h"
#import "Tr8n.h"
#import "Tr8nApiClient.h"

@implementation Tr8nLanguage

@synthesize application, locale, englishName, nativeName, rightToLeft, contexts, cases, flagUrl;

+ (Tr8nLanguage *) defaultLanguage {
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"en-US" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    NSError *error = nil;
    NSDictionary *attributes = (NSDictionary *) [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return [[Tr8nLanguage alloc] initWithAttributes:attributes];
}

- (NSString *) cacheKey {
    return [NSString stringWithFormat:@"%@/language", locale];
}

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"application"])
        self.application = [attributes objectForKey:@"application"];
    
    self.locale = [attributes objectForKey:@"locale"];
    self.englishName = [attributes objectForKey:@"english_name"];
    self.nativeName = [attributes objectForKey:@"native_name"];
    self.rightToLeft = [attributes objectForKey:@"right_to_left"];
    self.flagUrl = [attributes objectForKey:@"flag_url"];
    
    NSMutableDictionary *languageCases = [NSMutableDictionary dictionary];
    if ([attributes objectForKey:@"cases"]) {
        NSDictionary *casesHash = (NSDictionary *) [attributes objectForKey:@"cases"];
        for (NSString *key in [casesHash allKeys]) {
            NSDictionary *caseData = [casesHash objectForKey:key];
            Tr8nLanguageCase *lcase = [[Tr8nLanguageCase alloc] initWithAttributes:caseData];
            lcase.keyword = key;
            lcase.language = self;
            [languageCases setObject:lcase forKey:key];
        }
    }
    self.cases = languageCases;
    
    NSMutableDictionary *languageContexts = [NSMutableDictionary dictionary];
    if ([attributes objectForKey:@"contexts"]) {
        NSDictionary *contextsHash = (NSDictionary *) [attributes objectForKey:@"contexts"];
        for (NSString *key in [contextsHash allKeys]) {
            NSDictionary *contextData = [contextsHash objectForKey:key];
            Tr8nLanguageContext *lcontext = [[Tr8nLanguageContext alloc] initWithAttributes:contextData];
            lcontext.keyword = key;
            lcontext.language = self;
            [languageContexts setObject:lcontext forKey:key];
        }
    }
    self.contexts = languageContexts;
}

- (void) load {
    NSDictionary *responseObject = (NSDictionary *) [self.application.apiClient get: [NSString stringWithFormat:@"languages/%@", self.locale]
                                                                   params: @{}
                                                                  options: @{@"cache_key": [self cacheKey]}];
    if (responseObject) [self updateAttributes:responseObject];
}

- (Tr8nLanguageContext *) contextByKeyword: (NSString *) keyword {
    return [self.contexts objectForKey:keyword];
}

- (Tr8nLanguageContext *) contextByTokenName: (NSString *) tokenName {
    for (Tr8nLanguageContext *context in [self.contexts allValues]) {
        if ([context isApplicableToTokenName:tokenName]) {
            return context;
        }
    }
    return nil;
}

- (Tr8nLanguageCase *) languageCaseByKeyword: (NSString *) keyword {
    return [self.cases objectForKey:keyword];
}

- (BOOL) hasDefinitionData {
    if ([[self.contexts allValues] count] > 0)
        return YES;
    return NO;
}

- (BOOL) isDefault {
    if (self.application == nil)
        return YES;
    if ([self.application.defaultLocale isEqual: self.locale])
        return YES;
    return NO;
}

- (NSString *) htmlDirection {
    if ([self.rightToLeft isEqual:@YES])
        return @"rtl";
    return @"ltr";
}

- (NSString *) htmlAlignmentWithLtrDefault: (NSString *) defaultAlignment {
    if ([self.rightToLeft isEqual:@YES])
        return defaultAlignment;
    if ([defaultAlignment isEqual: @"right"])
        return @"left";
    return @"right";
}

- (NSString *) name {
    return self.englishName;
}

- (NSString *) fullName {
    if (self.nativeName == nil || [self.englishName isEqualToString:self.nativeName]) {
        return self.englishName;
    }
    return [NSString stringWithFormat:@"%@ - %@", self.englishName, self.nativeName];
}

- (NSObject *) valueFromOptions: (NSDictionary *) options forKey: (NSString *) key withDefault: (NSObject *) defaultValue {
    
    NSObject *value = [options objectForKey:key];
    if (value) return value;
    
    value = [Tr8n blockOptionForKey:key];
    if (value) return value;
    
    return defaultValue;
}

- (NSObject *) translationKeyWithKey: (NSString *) key label: (NSString *) label description:(NSString *) description options: (NSDictionary *) options {
    NSString *keyLocale = (NSString *) [self valueFromOptions:options forKey:@"locale" withDefault:[[Tr8n sharedInstance] defaultLanguage].locale];
    NSNumber *keyLevel = (NSNumber *) [self valueFromOptions:options forKey:@"level" withDefault:[NSNumber numberWithInt:0]];
    
    NSMutableDictionary *keyAttributes = [NSMutableDictionary dictionaryWithDictionary:@{
        @"key":             key,
        @"label":           label,
        @"locale":          keyLocale,
        @"level":           keyLevel
    }];

    if (description)
        [keyAttributes setObject:description forKey:@"description"];
    
    if (self.application)
        [keyAttributes setObject:self.application forKey:@"application"];

    return [[Tr8nTranslationKey alloc] initWithAttributes:keyAttributes];
}

- (NSObject *) translate:(NSString *) label withDescription:(NSString *) description andTokens: (NSDictionary *) tokens andOptions: (NSDictionary *) options {
    NSString *keyHash = [Tr8nTranslationKey generateKeyForLabel:label andDescription:description];
    Tr8nTranslationKey *translationKey = (Tr8nTranslationKey *) [self translationKeyWithKey:keyHash label:label description:description options:options];
    
    if ([tokens objectForKey:@"viewing_user"] == nil && [Tr8n configuration].viewingUser != nil) {
        NSMutableDictionary *tokensWithViewingUser = [NSMutableDictionary dictionaryWithDictionary:tokens];
        [tokensWithViewingUser setObject:[Tr8n configuration].viewingUser forKey:@"viewing_user"];
        tokens = tokensWithViewingUser;
    }

    if ([application isKeyRegistrationEnabled]) {
        NSString *sourceKey = (NSString *) [self valueFromOptions:options forKey:@"source" withDefault:[[Tr8n sharedInstance] currentSource]];
        if (sourceKey == nil) sourceKey = @"Tr8n";
        
        Tr8nSource *source = (Tr8nSource *) [self.application sourceForKey:sourceKey andLocale: self.locale];
        if (source) {
            NSArray *translations = [source translationsForKey:keyHash inLanguage:self.locale];
            if (translations != nil) {
                [translationKey setTranslations:translations];
                return [translationKey translateToLanguage: self withTokens: tokens andOptions: options];
            }
            [self.application registerMissingTranslationKey:translationKey forSource: source];
        }
    }

    // fallback onto global application translation keys
    NSArray *matchedTranslations = [self.application translationsForKey:keyHash inLanguage:self.locale];
    if (matchedTranslations != nil) {
        [translationKey setTranslations:matchedTranslations];
        return [translationKey translateToLanguage: self withTokens: tokens andOptions: options];
    }
    
    return [translationKey translateToLanguage: self withTokens: tokens andOptions: options];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"%@ (%@)", self.englishName, self.locale];
}

@end
