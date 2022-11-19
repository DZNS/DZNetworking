//
//  DZOAuthSession.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 10/2/15.
//  Copyright © 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZOAuthSession.h"

#import "../ResponseParsers/DZJSONResponseParser.h"

#import "../Utilities/NSDictionary+Extend.h"
#import "NSString+Coders.h"
#import <CommonCrypto/CommonCrypto.h>

@interface DZOAuthSession ()

@property (nonatomic, copy, readwrite) NSURL * _Nullable baseURL;
@property (nonatomic, copy, readwrite) NSString * _Nonnull consumerKey;
@property (nonatomic, copy, readwrite) NSString * _Nonnull consumerSecret;

@property (nonatomic, strong, readwrite) DZURLSession *session;

@end

@implementation DZOAuthSession

#pragma mark - Overrides

- (NSDictionary *)commonParameters
{
    return @{};
}

-(NSString *)signingKey
{
    
    return [NSString stringWithFormat:@"%@&%@", self.consumerSecret, self.accessSecret?:@""];
    
}

#pragma mark -

- (NSString *)oAuthVersion
{
    return @"1.0";
}

#pragma mark -

- (instancetype)initWithConsumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                            baseURL:(NSURL * _Nonnull)baseURL
{
    
    NSAssert(consumerKey, @"Please pass a consumer key when initializing DZOAuthSession");
    NSAssert(consumerSecret, @"Please pass a consumer secret when initializing DZOAuthSession");
    NSAssert(baseURL, @"Please pass a base URL when initializing DZOAuthSession");
    
    if(self = [super init])
    {
        _consumerKey = consumerKey;
        _consumerSecret = consumerSecret;
        _baseURL = baseURL;
        
        _session = [[DZURLSession alloc] init];
        _session.baseURL = baseURL;
        _session.useActivityManager = YES;
        _session.responseParser = [DZJSONResponseParser new];
        
    }
    
    return self;
    
}

- (void)beginAuthWithAdditionParams:(NSDictionary *_Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    if(!self.requestTokenURL)
    {
        // ToDo: provide better info in the error.
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"com.dzoauth" code:-1 userInfo:@{}];
            errorCB(error, nil, nil);
        }
            
        return;
    }
    
    if(!params)
        params = @{};
    
    if(self.oAuthCallback)
        params = [params dz_extend:@{@"oauth_callback" : [self.oAuthCallback encodeURI]}];
    
    NSMutableDictionary *signedParams = [self sign:self.requestTokenURL method:@"GET" parameters:params].mutableCopy;
    
    NSURLComponents *components = [NSURLComponents componentsWithString:self.requestTokenURL.absoluteString];
    
    NSArray <NSURLQueryItem *> *items = [self queryItemsFromParams:signedParams];
    
    components.queryItems = items;
    
    NSURL *URL = components.URL;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    __unused NSURLSessionTask *task = [self.session GET:request success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSURLComponents *components = [NSURLComponents new];
        components.query = responseStr;
        
        if(!components.queryItems || !components.queryItems.count)
        {
            //todo: better error information
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:@"com.dzoauth" code:1 userInfo:@{}];
                errorCB(error, response, task);
            }
            
            return;
        }
        
        NSDictionary *params = [self dictionaryRepresentationForQueryItems:components.queryItems];
        
        if([params valueForKey:@"oauth_token_secret"])
        {
            self.accessSecret = [params valueForKey:@"oauth_token_secret"];
        }
        
        NSString *tempAccessToken = [params valueForKey:@"oauth_token"];
        
        NSURLComponents *authComponents = [[NSURLComponents alloc] initWithString:self.userAuthorizationURL.absoluteString];
        authComponents.query = [NSString stringWithFormat:@"oauth_token=%@", tempAccessToken];
        
        if (successCB)
            successCB(authComponents.URL, response, task);
        
    } error:errorCB];
    
}

- (void)finishAuthWithToken:(NSString *)token
                          verifier:(NSString *)verifier success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    NSDictionary *params = @{@"oauth_token" : token,
                             @"oauth_verifier" : verifier};
    
    NSDictionary *signedParams = [self sign:self.accessTokenURL method:@"GET" parameters:params];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:self.accessTokenURL.absoluteString];
    
    NSArray <NSURLQueryItem *> *items = [self queryItemsFromParams:signedParams];
    
    components.queryItems = items;
    
    NSURL *URL = components.URL;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    [self.session GET:request success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSURLComponents *components = [NSURLComponents new];
        components.query = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        if (successCB)
            successCB([self dictionaryRepresentationForQueryItems:[components queryItems]], response, task);
        
    } error:errorCB];
    
}

#pragma mark -

- (NSURLSessionTask *)GET:(NSString * _Nonnull)URI
                 parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session GET:URI parameters:[self sign:URI method:@"GET" parameters:params] success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)POST:(NSString * _Nonnull)URI
                  parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session POST:URI parameters:[self sign:URI method:@"POST" parameters:params] success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)POST:(NSString * _Nonnull)URI
                 queryParams:(NSDictionary * _Nullable)query
                  parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session POST:URI queryParams:query parameters:[self sign:URI method:@"POST" parameters:params] success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)PUT:(NSString * _Nonnull)URI
                 parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session PUT:URI parameters:[self sign:URI method:@"PUT" parameters:params] success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)PUT:(NSString * _Nonnull)URI
                queryParams:(NSDictionary * _Nullable)query
                 parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session PUT:URI queryParams:query parameters:[self sign:URI method:@"PUT" parameters:params] success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)PATCH:(NSString * _Nonnull)URI
                   parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session PATCH:URI parameters:[self sign:URI method:@"PATCH" parameters:params] success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)DELETE:(NSString * _Nonnull)URI
                    parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session GET:URI parameters:[self sign:URI method:@"GET" parameters:params] success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)HEAD:(NSString * _Nonnull)URI
                  parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session HEAD:URI parameters:[self sign:URI method:@"HEAD" parameters:params] success:successCB error:errorCB];
    
}


- (NSURLSessionTask *)OPTIONS:(NSString * _Nonnull)URI
                     parameters:(NSDictionary * _Nonnull)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session OPTIONS:URI parameters:[self sign:URI method:@"OPTIONS" parameters:params] success:successCB error:errorCB];
    
}

#pragma mark - URL Building

- (NSDictionary *)sign:(id _Nonnull)URI
                method:(NSString *)method
            parameters:(NSDictionary *_Nullable)params
{
    
    NSURL *URL = nil;
    
    if([URI isKindOfClass:[NSURL class]])
    {
        URL = URI;
    }
    else
    {
        URL = [NSURL URLWithString:URI relativeToURL:self.baseURL];
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:URL.absoluteString];
    
    {
        
        if(!params)
        {
            params = @{};
        }
        else
        {
            //encode all the things!
            NSMutableDictionary *dict = params.mutableCopy;
            
            [dict enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
               
                if([obj isKindOfClass:[NSString class]])
                {
                    [dict setObject:[obj encodeURI] forKey:key];
                }
                
            }];
            
            params = [dict copy];
            
        }
        
        params = [params dz_extend:@{@"oauth_consumer_key": [self consumerKey],
                                     @"oauth_timestamp": [self timestamp],
                                     @"oauth_nonce" : [self nonce],
                                     @"oauth_signature_method" : [self signatureMethod],
                                     @"oauth_version": [self oAuthVersion]}];
        
        if(self.accessToken)
        {
            params = [params dz_extend:@{@"oauth_token" : self.accessToken}];
        }
        
        if([[self commonParameters] count])
        {
            NSMutableDictionary *dict = [self commonParameters].mutableCopy;
            [dict addEntriesFromDictionary:params];
            
            params = dict.copy;
        }
        
    }
    
    components.queryItems = [self queryItemsFromParams:params];
    
    NSString *A = [method uppercaseString],
             *B = [[URL absoluteString] encodeURI],
             *C = [components.query encodeURI];
    
    NSString *stringToSign = [NSString stringWithFormat:@"%@&%@&%@", A, B, C];
//    NSLog(@"%@", stringToSign);
    NSString *signature = [self hashedValueWithKey:[self signingKey] andData:stringToSign];
    
    components.queryItems = [components.queryItems arrayByAddingObject:[[NSURLQueryItem alloc] initWithName:@"oauth_signature" value:signature]];
    
    NSMutableDictionary *dict = [self dictionaryRepresentationForQueryItems:components.queryItems].mutableCopy;
    
    {
        // now decode everything back.
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            if([obj isKindOfClass:[NSString class]])
            {
                [dict setObject:[obj decodeURI] forKey:key];
            }
            
        }];
        
        components.queryItems = [self queryItemsFromParams:dict];
    }
    
    return dict.copy;
    
}

#pragma mark - URI Params

- (NSString *_Nonnull)nonce
{

    return [[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    
}

- (NSString *_Nonnull)timestamp
{

    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSNumber *number = @(interval);
    number = @([number integerValue]-1);
    return [number stringValue];
}

- (NSString *_Nonnull)signatureMethod
{
    
    return @"HMAC-SHA1";
    
}

#pragma mark - Helpers

- (NSString *)hashedValueWithKey:(NSString *)secret andData:(NSString *)text
{
    
    
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
    CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], result);
    
    //Base64 Encoding
    NSData *HMAC = [[NSData alloc] initWithBytes:result length:sizeof(result)];
    return [HMAC base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
}

- (NSDictionary <NSString *, id>* _Nonnull)dictionaryRepresentationForQueryItems:(NSArray <NSURLQueryItem *>* _Nonnull)items
{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:items.count];
    
    for(NSURLQueryItem *item in items)
    {
        [dict setObject:item.value forKey:item.name];
    }
    
    return dict.copy;
    
}

- (NSArray <NSURLQueryItem *> *)queryItemsFromParams:(NSDictionary *)params
{
    
    NSMutableArray <NSURLQueryItem *>*queryItems = [NSMutableArray arrayWithCapacity:[[params allKeys] count]];
    
    NSArray *sortedKeys = [[params allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for(NSString *key in sortedKeys)
    {
        
        id value = params[key];
        
        if(![value isKindOfClass:[NSString class]])
        {
            value = [value stringValue];
        }
        
        NSURLQueryItem *item = [[NSURLQueryItem alloc] initWithName:key value:value];
        
        [queryItems addObject:item];
        
    }
    
    return queryItems.copy;
    
}

@end
