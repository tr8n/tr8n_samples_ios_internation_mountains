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

#import "Tr8nCache.h"

@implementation Tr8nCache

@synthesize path;

- (id) init {
    if (self == [super init]) {
        [self initCachePath];
    }
    return self;
}

- (void) initCachePath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    cachePath = [cachePath stringByAppendingPathComponent:@"Tr8n"];
    NSLog(@"Cache path: %@", cachePath);
    [self validatePath: cachePath];
    self.path = cachePath;
}

- (void) validatePath: (NSString *) cachePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath])
        return;
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"Failed to create cache folder at %@", cachePath);
    }
}

- (NSString *) cachePathForKey: (NSString *) key {
    NSString *cachePath = self.path;

    NSArray *components = [key componentsSeparatedByString:@"/"];
    if ([components count] > 1) {
        cachePath = [NSString stringWithFormat:@"%@/%@", self.path, [[components subarrayWithRange:NSMakeRange(0, [components count]-1)] componentsJoinedByString:@"/"]];
        key = [components lastObject];
    }

    [self validatePath:cachePath];
    return [cachePath stringByAppendingPathComponent: [NSString stringWithFormat:@"/%@.json", key]];
}

- (NSObject *) fetchObjectForKey: (NSString *) key {
    NSString *objectPath = [self cachePathForKey: key];
    
//    NSLog(@"Loading %@ at path %@", key, objectPath);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:objectPath]) {
        return nil;
    }
    
    NSData *jsonData = [NSData dataWithContentsOfFile:objectPath];
//    NSString* jsonString = [NSString stringWithUTF8String:[jsonData bytes]];
//    NSLog(@"%@", jsonString);
    
    NSError *error = nil;
    NSObject *result = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        NSLog(@"Error trace: %@", error);
        return nil;
    }
    
    return result;
}

- (void) resetCacheForKey: (NSString *) key {
    NSString *objectPath = [self cachePathForKey: key];
    if (![[NSFileManager defaultManager] fileExistsAtPath:objectPath]) {
        return;
    }

    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:objectPath error:&error];

    if (error) {
        NSLog(@"Failed to reset cache for key: %@", key);
    }
}

- (void) storeData: (NSData *) data forKey: (NSString *) key withOptions: (NSDictionary *) options {
    NSString *objectPath = [self cachePathForKey: key];
    NSLog(@"Saving %@ to cache %@", key, objectPath);
    NSData *copy = [NSData dataWithData:data];
    [copy writeToFile:objectPath atomically:NO];
}

- (void) reset {
    NSFileManager* fm = [[NSFileManager alloc] init];
    NSDirectoryEnumerator* en = [fm enumeratorAtPath:self.path];
    NSError* err = nil;
    BOOL res;
    
    NSString* file;
    while (file = [en nextObject]) {
        res = [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:&err];
        if (!res && err) {
            NSLog(@"Failed to delete cache at path: %@", err);
        }
    }
}

- (void) backupCacheForLocale: (NSString *) locale {
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", self.path, locale];
    NSString *backupPath = [NSString stringWithFormat:@"%@.bak", cachePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:cachePath]) {
        return;
    }

    NSError *error = nil;
    if ([fileManager fileExistsAtPath:backupPath]) {
        [fileManager removeItemAtPath:backupPath error:&error];
    }

    [fileManager moveItemAtPath:cachePath toPath:backupPath error:&error];
    if (error) {
        NSLog(@"Failed to backup locale path %@", cachePath);
    }
}

- (void) restoreCacheBackupForLocale: (NSString *) locale {
    NSString *cachePath = [NSString stringWithFormat:@"%@/%@", self.path, locale];
    NSString *backupPath = [NSString stringWithFormat:@"%@.bak", cachePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:backupPath]) {
        return;
    }
    
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:cachePath]) {
        [fileManager removeItemAtPath:cachePath error:&error];
    }
    
    [fileManager moveItemAtPath:backupPath toPath:cachePath error:&error];
    if (error) {
        NSLog(@"Failed to restore backup for locale path %@", cachePath);
    }
}


@end
