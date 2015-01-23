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

#import "TmlLanguageCase.h"
#import "TmlLanguageCaseRule.h"

@implementation TmlLanguageCase

@synthesize language, application, keyword, latinName, nativeName, description, rules;

- (void) updateAttributes: (NSDictionary *) attributes {
    if ([attributes objectForKey:@"language"])
        self.language = [attributes objectForKey:@"language"];

    self.application = [attributes objectForKey:@"application"];
    self.keyword = [attributes objectForKey:@"keyword"];
    self.latinName = [attributes objectForKey:@"latin_name"];
    self.nativeName = [attributes objectForKey:@"native_name"];
    self.description = [attributes objectForKey:@"description"];
    
    NSMutableArray *caseRules = [NSMutableArray array];
    if ([attributes objectForKey:@"rules"]) {
        for (NSDictionary *ruleData in [attributes objectForKey:@"rules"]) {
            TmlLanguageCaseRule *rule = [[TmlLanguageCaseRule alloc] initWithAttributes:ruleData];
            rule.languageCase = self;
            [caseRules addObject:rule];
        }
    }
    self.rules = caseRules;
}

- (NSObject *) findMatchingRule: (NSString *) value {
    return [self findMatchingRule:value forObject:nil];
}

- (NSObject *) findMatchingRule: (NSString *) value forObject: (NSObject *) object {
    for (TmlLanguageCaseRule *rule in self.rules) {
        NSNumber *result = [rule evaluate:value forObject:object];
        if ([result isEqual: @YES])
            return rule;
    }
    
    return nil;
}

- (NSString *) apply: (NSString *) value {
    return [self apply:value forObject:nil];
}

- (NSString *) apply: (NSString *) value forObject: (NSObject *) object {
    NSArray *elements;
    
    if ([self.application isEqualToString:@"phrase"]) {
        elements = @[value];
    } else {
        NSString *pattern = @"\\s\\/,;:"; // split by space, comma, ;, : and /
        NSString *tempSeparator = @"%|%";
        NSString *cleanedValue = [value stringByReplacingOccurrencesOfString: pattern
                                                                  withString: tempSeparator
                                                                     options: NSRegularExpressionSearch
                                                                       range: NSMakeRange(0, value.length)];
        elements = [cleanedValue componentsSeparatedByString: tempSeparator];
    }

    // TODO: use RegEx to split words and assemble them right back
    // The current solution will not work for Палиграф Палиграфович -> Палиграфа Палиграфаович

    NSString *transformedValue = [NSString stringWithString:value];
    for (NSString *element in elements) {
        TmlLanguageCaseRule *rule = (TmlLanguageCaseRule *) [self findMatchingRule:element forObject:object];
        if (rule == nil)
            continue;
        
        NSString *adjustedValue = [rule apply:element];
        transformedValue = [transformedValue stringByReplacingOccurrencesOfString: element
                                                                       withString: adjustedValue
                                                                          options: 0
                                                                            range: NSMakeRange(0, transformedValue.length)];
    }
    
    return transformedValue;
}

@end
