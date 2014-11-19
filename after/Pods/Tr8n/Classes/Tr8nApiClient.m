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

#import "Tr8nApiClient.h"
#import "Tr8n.h"
#import "Tr8nApplication.h"
#import "AFHTTPRequestOperationManager.h"

@implementation Tr8nApiClient

@synthesize application;

- (id) initWithApplication: (Tr8nApplication *) owner {
    if (self == [super init]) {
        self.application = owner;
    }
    return self;
}

- (NSString *) getAccessToken {
    if (self.application.accessToken == nil) {
        NSDictionary *accessTokenData = (NSDictionary *) [self post: @"oauth/token" params:@{
            @"client_id": self.application.key,
            @"client_secret": self.application.secret,
            @"grant_type": @"client_credentials"
        } options:@{@"unauthorized": @TRUE}];
        
        self.application.accessToken = [accessTokenData objectForKey:@"access_token"];
    }
    return self.application.accessToken;
}

- (NSString *) apiFullPath: (NSString *) path {
    if ([path rangeOfString:@"http"].location != NSNotFound)
        return path;

    if ([path isEqualToString:@"oauth/token"])
        return [NSString stringWithFormat:@"%@/%@", self.application.host, path];
    
    return [NSString stringWithFormat:@"%@/v1/%@", self.application.host, path];
}

- (NSDictionary *) apiParameters: (NSDictionary *) params {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    [parameters setObject:[self getAccessToken] forKey:@"access_token"];
    return parameters;
}

- (NSString *) urlEncode: (id) object {
    NSString *string = [NSString stringWithFormat: @"%@", object];
    return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

- (NSString*) urlEncodedStringFromParams: (NSDictionary *) params {
    NSMutableArray *parts = [NSMutableArray array];
    for (id paramKey in params) {
        id paramValue = [params objectForKey: paramKey];
        NSString *part = [NSString stringWithFormat: @"%@=%@", [self urlEncode: paramKey], [self urlEncode: paramValue]];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

- (NSObject*) get: (NSString *) path params: (NSDictionary *) params {
    return [self get:path params:params options: @{}];
}

- (void) get: (NSString *) path
      params: (NSDictionary *) params
     options: (NSDictionary *) options
     success: (void (^)(id responseObject)) success
     failure: (void (^)(NSError *error)) failure
{
    
    if ([options objectForKey:@"cache_key"]) {
        NSObject *attributes = [Tr8n.cache fetchObjectForKey:[options objectForKey:@"cache_key"]];
        if (attributes) {
            NSLog(@"Cache hit: %@", [options objectForKey:@"cache_key"]);
            success(attributes);
            return;
        }
    }
    
    NSString *fullPath = [self apiFullPath: path];
    NSLog(@"GET %@", fullPath);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET: fullPath
      parameters: [self apiParameters: params]
         success: ^(AFHTTPRequestOperation *operation, id responseObject) {
             //             NSLog(@"JSON: %@", responseObject);
             if ([responseObject isKindOfClass:NSDictionary.class]) {
                 NSDictionary *data = (NSDictionary *) responseObject;
                 if ([data valueForKey:@"error"] != nil) {
                     NSError *error = [NSError errorWithDomain:[data valueForKey:@"error"] code:0 userInfo:nil];
                     failure(error);
                 } else {
                     
                     if ([options objectForKey:@"cache_key"]) {
                         [Tr8n.cache storeData: [[operation responseString] dataUsingEncoding:NSUTF8StringEncoding]
                                        forKey: [options objectForKey:@"cache_key"] withOptions: @{}];
                     }
                     
                     success(responseObject);
                 }
             }
         } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: %@", error);
             failure(error);
         }];
}

- (void) post: (NSString *) path
       params: (NSDictionary *) params
      options: (NSDictionary *) options
      success: (void (^)(id responseObject)) success
      failure: (void (^)(NSError *error)) failure
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST: [self apiFullPath: path]
       parameters: [self apiParameters: params]
          success: ^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"JSON: %@", responseObject);
              if ([responseObject isKindOfClass:NSDictionary.class]) {
                  NSDictionary *data = (NSDictionary *) responseObject;
                  if ([data valueForKey:@"error"] != nil) {
                      NSError *error = [NSError errorWithDomain:[data valueForKey:@"error"] code:0 userInfo:nil];
                      failure(error);
                  } else {
                      success(responseObject);
                  }
              }
          } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
              failure(error);
          }];
}

- (NSObject*) get: (NSString *) path params: (NSDictionary *) params options: (NSDictionary *) options {
    
    if ([options objectForKey:@"cache_key"]) {
        NSObject *attributes = [Tr8n.cache fetchObjectForKey:[options objectForKey:@"cache_key"]];
        if (attributes) {
            NSLog(@"Cache hit: %@", [options objectForKey:@"cache_key"]);
            return attributes;
        } else {
            NSLog(@"Cache miss: %@", [options objectForKey:@"cache_key"]);
        }
    }
    
    if (![options valueForKey:@"unauthorized"])
        params = [self apiParameters: params];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [self apiFullPath: path], [self urlEncodedStringFromParams: params]]];
    
    NSLog(@"GET %@", [url absoluteString]);
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if (data == nil) {
        NSLog(@"Error trace: failed to load data");
        return nil;
    }
    
    //    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //    NSLog(@"Got json: %@", json);
    
    error = nil;
    NSObject *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error) {
        NSLog(@"Error trace: %@", error);
        return nil;
    }
    
    if ([responseObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *responseData = (NSDictionary *) responseObject;
        if ([responseData valueForKey:@"error"] != nil) {
            NSLog(@"Error trace: %@", [responseData valueForKey:@"error"]);
            return nil;
        }
    }
    
    if ([options objectForKey:@"cache_key"]) {
        [Tr8n.cache storeData: data forKey: [options objectForKey:@"cache_key"] withOptions: @{}];
    }
    
    return responseObject;
}

- (NSObject*) post: (NSString *) path params: (NSDictionary *) params options: (NSDictionary *) options {
    NSURL *url = [NSURL URLWithString:[self apiFullPath: path]];
    
    NSLog(@"POST %@", [url absoluteString]);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[self urlEncodedStringFromParams: params] dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error)
        NSLog(@"Error: %@", error.description);
    
    if (data == nil) {
        NSLog(@"Error trace: failed to load data");
        return nil;
    }
    
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Response: %@", json);
    
    error = nil;
    NSObject *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error) {
        NSLog(@"Error trace: %@", error);
        return nil;
    }
    
    if ([responseObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *responseData = (NSDictionary *) responseObject;
        if ([responseData valueForKey:@"error"] != nil) {
            NSLog(@"Error trace: %@", [responseData valueForKey:@"error"]);
            return nil;
        }
    }
    
    return responseObject;
}

@end
