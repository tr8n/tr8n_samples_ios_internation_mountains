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

#import "Tr8nApplication.h"
#import "Tr8nCache.h"
#import "Tr8nLanguage.h"
#import "Tr8nSource.h"
#import "Tr8nTranslation.h"
#import "Tr8n.h"
#import "Tr8nApiClient.h"
#import "Tr8nPostOffice.h"

@implementation Tr8nApplication

@synthesize host, key, secret, name, description, defaultLocale, threshold, features, tools;
@synthesize translations, languagesByLocales, sourcesByKeys, missingTranslationKeysBySources, scheduler;
@synthesize apiClient, postOffice;

+ (NSString *) cacheKey {
    return @"application";
}

- (id) initWithHost: (NSString *) appHost key: (NSString *) appKey secret: (NSString *) appSecret {
    if (self = [super init]) {
        self.host = appHost;
        self.key = appKey;
        self.secret = appSecret;

        self.apiClient = [[Tr8nApiClient alloc] initWithApplication:self];
        self.postOffice = [[Tr8nPostOffice alloc] initWithApplication:self];
        
        [self updateAttributes:@{@"name": @"Loading...",
                                 @"default_locale": @"en-US",
                                 @"treshold": [NSNumber numberWithInt:0]}];
        
        [self load];
        
        if ([self isKeyRegistrationEnabled]) {
            self.scheduler = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(submitMissingTranslationKeys) userInfo:nil repeats:YES];
        }

    }
    return self;
}

- (void) updateAttributes: (NSDictionary *) attributes {
    self.name = [attributes objectForKey:@"name"];
    self.description = [attributes objectForKey:@"description"];
    self.defaultLocale = [attributes objectForKey:@"default_locale"];
    self.threshold = [attributes objectForKey:@"threshold"];
    self.features = [attributes objectForKey:@"features"];
    self.tools = [attributes objectForKey:@"tools"];

    self.translations = [NSMutableDictionary dictionary];
    self.languagesByLocales = [NSMutableDictionary dictionary];
    self.sourcesByKeys = [NSMutableDictionary dictionary];
    self.missingTranslationKeysBySources = [NSMutableDictionary dictionary];
}

- (void) load {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([[UIDevice currentDevice] respondsToSelector:@selector(model)])
        [params setObject:[[UIDevice currentDevice] model] forKey:@"model"];
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"])
        [params setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] forKey:@"bundle_id"];
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDevelopmentRegion"])
        [params setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDevelopmentRegion"] forKey:@"locale"];
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"])
        [params setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] forKey:@"display_name"];
    
    NSDictionary *responseObject = (NSDictionary *) [self.apiClient get: @"applications/current"
                                                                 params: params
                                                                options: @{@"cache_key": [Tr8nApplication cacheKey]}];
    if (responseObject) [self updateAttributes:responseObject];
}

- (void) reload {
    [self resetCache];
    [self load];
}

- (NSString *) transltionsCacheKeyForLocale: (NSString *) locale {
    return [NSString stringWithFormat:@"%@/translations", locale];
}

- (void) resetTranslationsCacheForLocale: (NSString *) locale {
    [Tr8n.cache resetCacheForKey:[self transltionsCacheKeyForLocale:locale]];
}

- (void) updateTranslations:(NSDictionary *) data forLocale: locale {
    NSMutableDictionary *localeTranslations = [NSMutableDictionary dictionary];
    
    NSDictionary *results = [data objectForKey:@"results"];
    NSArray *translationsData;
    NSMutableArray *newTranslations;
    
//    NSLog(@"%@", data);

    for (NSString *tkey in [results allKeys]) {
        if (![results objectForKey:tkey]) continue;
        
        if ([[results objectForKey:tkey] isKindOfClass:[NSDictionary class]])
            translationsData = [[results objectForKey:tkey] objectForKey:@"translations"];
        else if ([[results objectForKey:tkey] isKindOfClass:[NSArray class]])
            translationsData = [results objectForKey:tkey];
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

- (void) loadTranslationsForLocale: (NSString *) locale
                       withOptions: (NSDictionary *) options
                           success: (void (^)()) success
                           failure: (void (^)(NSError *error)) failure
{
    
    NSMutableDictionary *loadOptions = [NSMutableDictionary dictionary];
    if (![options objectForKey:@"reload"])
        [loadOptions setObject: [self transltionsCacheKeyForLocale:locale] forKey:@"cache_key"];

    [self.apiClient get: @"applications/current/translations"
       params: @{@"locale": locale}
      options: loadOptions
      success: ^(id responseObject) {
          [self updateTranslations:responseObject forLocale:locale];
          [[NSNotificationCenter defaultCenter] postNotificationName: Tr8nTranslationsLoadedNotification object: locale];
          success();
      }
      failure: ^(NSError *error) {
          NSDictionary *data = (NSDictionary *) [Tr8n.cache fetchObjectForKey: [self transltionsCacheKeyForLocale:locale]];
          if (data) {
              [self updateTranslations:data forLocale:locale];
              success();
              return;
          }
          failure(error);
      }];
}

- (NSArray *) translationsForKey:(NSString *) translationKey inLanguage: (NSString *) locale {
    if (!self.translations && ![self.translations objectForKey:locale]) return nil;
    return [[self.translations objectForKey:locale] objectForKey:translationKey];
}

- (void) resetTranslations {
    self.translations = @{};
    self.sourcesByKeys = [NSMutableDictionary dictionary];
}

- (NSObject *) languageForLocale: (NSString *) locale reload: (BOOL) reload {
    if (locale == nil)
        return nil;
    
    if ([self.languagesByLocales objectForKey:locale] != nil) {
        Tr8nLanguage *language = [self.languagesByLocales objectForKey:locale];
        if (reload) [language reload];
        return language;
    }
    
    Tr8nLanguage *language = [[Tr8nLanguage alloc] initWithAttributes:@{@"locale": locale, @"application": self}];
    [language load];
    [self.languagesByLocales setObject:language forKey:locale];
    
    return language;
}

- (NSObject *) languageForLocale: (NSString *) locale {
    return [self languageForLocale:locale reload:NO];
}

- (NSObject *) sourceForKey: (NSString *) sourceKey andLocale: (NSString *) locale reload: (BOOL) reload {
    if (sourceKey == nil)
        return nil;
    
    if ([self.sourcesByKeys objectForKey:sourceKey] != nil) {
        Tr8nSource *source = (Tr8nSource *) [self.sourcesByKeys objectForKey:sourceKey];
        if (reload) [source loadTranslationsForLocale:locale];
        return source;
    }
    
    Tr8nSource *source = [[Tr8nSource alloc] initWithAttributes:@{@"key": sourceKey, @"application": self}];
    [source loadTranslationsForLocale:locale];
    [self.sourcesByKeys setObject:source forKey:sourceKey];
    
    return source;
}

- (NSObject *) sourceForKey: (NSString *) sourceKey andLocale: (NSString *) locale {
    return [self sourceForKey: sourceKey andLocale:locale reload:NO];
}

- (void) reloadSource: (NSString *) sourceKey {
    [self sourceForKey:sourceKey andLocale: [[Tr8n sharedInstance] currentLanguage].locale reload:YES];
}

- (BOOL) isKeyRegistrationEnabled {
    return (self.secret != nil);
}

- (void) registerMissingTranslationKey: (NSObject *) translationKey forSource: (NSObject *) source {
    if (![self isKeyRegistrationEnabled])
        return;
    
    if (self.missingTranslationKeysBySources == nil) {
        self.missingTranslationKeysBySources = [NSMutableDictionary dictionary];
    }
    
    Tr8nSource *tSource = (Tr8nSource *) source;
    NSMutableDictionary *sourceKeys = [self.missingTranslationKeysBySources objectForKey:tSource.key];
    if (sourceKeys == nil) {
        sourceKeys = [NSMutableDictionary dictionary];
        [self.missingTranslationKeysBySources setObject:sourceKeys forKey:tSource.key];
    }
    
    Tr8nTranslationKey *tkey = (Tr8nTranslationKey *) translationKey;
    if ([sourceKeys objectForKey:tkey.key] == nil) {
        [sourceKeys setObject:tkey forKey:tkey.key];
    }
}

- (void) submitMissingTranslationKeys {
    if (![self isKeyRegistrationEnabled])
        return;
    
    if (self.missingTranslationKeysBySources == nil
        || [[self.missingTranslationKeysBySources allKeys] count] == 0) {
        return;
    }

    NSLog(@"Submitting missing translations...");

    NSMutableArray *params = [NSMutableArray array];

    NSArray *sourceKeys = [self.missingTranslationKeysBySources allKeys];
    for (NSString *sourceKey in sourceKeys) {
        NSDictionary *keys = [self.missingTranslationKeysBySources objectForKey:sourceKey];
        NSMutableArray *keysData = [NSMutableArray array];
        for (Tr8nTranslationKey *tkey in [keys allValues]) {
            [keysData addObject:[tkey toDictionary]];
        }
        
        [params addObject:@{@"source": sourceKey, @"keys": keysData}];
    }
    
    [self.missingTranslationKeysBySources removeAllObjects];
    
    [self.apiClient post: @"sources/register_keys"
        params: @{@"source_keys": [self.class jsonFromObject: params]}
       options: @{}
       success: ^(id responseObject) {
           for (NSString *sourceKey in sourceKeys) {
               [self sourceForKey:sourceKey andLocale:[[[Tr8n sharedInstance] currentLanguage]locale] reload:YES];
           }
       } failure: ^(NSError *error) {
           
       }];
}

@end
