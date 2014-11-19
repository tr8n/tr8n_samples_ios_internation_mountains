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

#import "Tr8nSource.h"
#import "Tr8nApiClient.h"
#import "Tr8nConfiguration.h"
#import "Tr8nTranslation.h"

@implementation Tr8nSource

@synthesize application, key, translations;

+ (NSString *) cacheKeyForLocale: (NSString *) locale andKey: (NSString *) key {
    return [NSString stringWithFormat:@"%@/sources/%@", locale, key];
}

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"application"])
        self.application = [attributes objectForKey:@"application"];

    self.key = [attributes objectForKey:@"key"];
    self.translations = @{};
}

- (void) updateTranslations:(NSDictionary *) data forLocale: locale {
    NSMutableDictionary *localeTranslations = [NSMutableDictionary dictionary];
    
    NSArray *translationsData;
    NSMutableArray *newTranslations;
    
    for (NSString *tkey in [data allKeys]) {
        if (![data objectForKey:tkey]) continue;
        
        if ([[data objectForKey:tkey] isKindOfClass:[NSDictionary class]])
            translationsData = [[data objectForKey:tkey] objectForKey:@"translations"];
        else if ([[data objectForKey:tkey] isKindOfClass:[NSArray class]])
            translationsData = [data objectForKey:tkey];
        else
            continue;
        
        newTranslations = [NSMutableArray array];
        for (NSDictionary* translation in translationsData) {
            [newTranslations addObject:[[Tr8nTranslation alloc] initWithAttributes:@{
                 @"label": [translation valueForKey:@"label"],
                 @"locale": ([translation valueForKey:@"locale"] == nil ? locale : [translation valueForKey:@"locale"]),
                 @"context": ([translation valueForKey:@"context"] == nil ? @{} : [translation valueForKey:@"context"]),
             }]];
        }
        
        [localeTranslations setObject:newTranslations forKey:tkey];
    }
    
    NSMutableDictionary *trans = [NSMutableDictionary dictionaryWithDictionary:self.translations];
    [trans setObject:localeTranslations forKey:locale];
    self.translations = trans;
}

- (void) loadTranslationsForLocale: (NSString *) locale {
    NSMutableDictionary *loadOptions = [NSMutableDictionary dictionary];
    [loadOptions setValue: [Tr8nSource cacheKeyForLocale:locale andKey: self.key] forKey:@"cache_key"];
     NSString *apiSourceKey = [Tr8nConfiguration md5: self.key];
     NSDictionary *data = (NSDictionary *) [self.application.apiClient get: [NSString stringWithFormat: @"sources/%@/translations", apiSourceKey]
                                                                    params: @{@"locale": locale}
                                                                   options: loadOptions];
    if (data) [self updateTranslations:data forLocale:locale];
}

- (NSArray *) translationsForKey:(NSString *) translationKey inLanguage: (NSString *) locale {
    if (!self.translations && ![self.translations objectForKey:locale]) return nil;
    return [[self.translations objectForKey:locale] objectForKey:translationKey];
}

@end
