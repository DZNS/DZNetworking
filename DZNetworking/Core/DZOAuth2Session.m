//
//  DZOAuth2Session.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 31/05/19.
//  Copyright © 2019 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZOAuth2Session.h"

#import <CoreServices/CoreServices.h>
#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>

#import "DZJSONResponseParser.h"

#import "NSDictionary+Extend.h"
#import "NSString+Coders.h"
#import "OMGHTTPURLRQ.h"

@interface DZOAuth2Session () {
    
}

@property (nonatomic, copy) NSString *clientID;

@property (nonatomic, copy) NSString *clientSecret;

@property (nonatomic, copy) NSString *serviceName;

@property (nonatomic, copy, readwrite) NSString *token;

@property (nonatomic, copy, readwrite) NSString *tokenID;

@property (nonatomic, copy) NSString *authorizationURL;

@property (nonatomic, copy) NSString *redirectURL;

@property (nonatomic, copy) NSString *tokenURL;

@property (nonatomic, copy, readwrite) NSString * _Nonnull scope;

@property (nonatomic, strong) DZURLSession *session;

@property (nonatomic, copy) NSString *accountName;

- (NSString * _Nonnull)username;

@end

@implementation DZOAuth2Session

- (instancetype)initWithClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret serviceName:(NSString *)serviceName authorizationURL:(NSString * _Nonnull)authorizationURL tokenURL:(NSString *)tokenURL redirectURL:(NSString * _Nonnull)redirectURL scope:(NSString * _Nonnull)scope {
    
    NSAssert(clientID, @"Client ID must be defined for initializing a OAuth2 Session");
    NSAssert(clientSecret, @"Client Secret must be defined for initializing a OAuth2 Session");
    NSAssert(authorizationURL, @"Authorization URL must be defined for initializing a OAuth2 Session");
    NSAssert(tokenURL, @"Token URL must be defined for initializing a OAuth2 Session");
    NSAssert(redirectURL, @"Redirect URL must be defined for initializing a OAuth2 Session");
    
    if (self = [super init]) {
        
        self.clientID = clientID;
        self.clientSecret = clientSecret;
        self.serviceName = serviceName;
        self.authorizationURL = authorizationURL;
        self.tokenURL = tokenURL;
        self.redirectURL = redirectURL;
        self.scope = scope;
        
        // if the service name is defined, check if the credentials are available in the keychain for resuming the session
        if (self.serviceName != nil) {
            
            NSString *username = self.username;
            NSString *token = [self getKeychainItem:username];
            NSString *tokenID = [self getKeychainItem:[username stringByAppendingString:@"-ID"]];
            
            self.token = token;
            self.tokenID = tokenID;
            
        }
        
        self.session = [[DZURLSession alloc] init];
        self.session.useActivityManager = YES;
        self.session.responseParser = [DZJSONResponseParser new];
        
        __weak typeof(self) weakSelf = self;
        
        self.session.requestModifier = ^NSMutableURLRequest *(NSMutableURLRequest *request) {
            
            typeof(weakSelf) sself = weakSelf;
          
            NSString *bearer = [NSString stringWithFormat:@"Bearer %@", sself.token];
            
            [request setValue:bearer forHTTPHeaderField:@"Authorization"];
            
            return request;
            
        };
    
    }
    
    return self;
    
}

- (NSURL *)authorize {
    
    if (_state != nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"An active authorization flow is already in progress" userInfo:nil];
    }
    
    _state = [self hashedValueWithKey:[self timestamp] andData:self.serviceName];
    
    NSDictionary *params = @{@"response_type": @"code",
                             @"client_id": self.clientID,
                             @"redirect_uri": self.redirectURL,
                             @"scope": self.scope,
                             @"state": _state
                             };
    
    NSLog(@"State:%@", _state);
    
    NSMutableURLRequest *mutableRequest = [OMGHTTPURLRQ GET:self.authorizationURL :params error:nil];

    return mutableRequest.URL;
    
}

- (void)verifyOAuthCallback:(NSURL *)url success:(void (^ _Nullable)(void))successCB error:(void (^ _Nullable)(NSError * _Nonnull))errorCB {
    
    if (url == nil) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:NSCocoaErrorDomain code:404 userInfo:@{NSLocalizedDescriptionKey: @"An invalid or no URL was provided"}]);
        }
        return;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:nil];
    
    NSArray <NSURLQueryItem *> *queryItems = components.queryItems;
    
    // ensure the state is replied back and it matches
    NSString *state = [self valueForQueryItemKey:@"state" from:queryItems];
    
    if (state == nil) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:NSCocoaErrorDomain code:401 userInfo:@{NSLocalizedDescriptionKey: @"An invalid or no state was provided by the OAuth2 service."}]);
        }
        return;
    }
    
    if ([state isEqualToString:_state] == NO) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:NSCocoaErrorDomain code:401 userInfo:@{NSLocalizedDescriptionKey: @"The state generated does not match the state provided by the OAuth2 service. Halting."}]);
        }
        return;
    }
    
    NSString *code = [self valueForQueryItemKey:@"code" from:queryItems];
    
    if (code == nil) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:NSCocoaErrorDomain code:404 userInfo:@{NSLocalizedDescriptionKey: @"An invalid or no code was provided by the OAuth2 service."}]);
        }
        return;
    }
    
    NSDictionary *params = @{@"grant_type": @"authorization_code",
                             @"client_id": self.clientID,
                             @"client_secret": self.clientSecret,
                             @"redirect_uri": self.redirectURL,
                             @"code": code
                             };
    
    NSMutableURLRequest *mutableRequest = [OMGHTTPURLRQ GET:self.tokenURL :params error:nil];
    mutableRequest.HTTPMethod = @"POST";
    
    [self.session POST:mutableRequest success:^(NSDictionary <NSString *, NSString *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self.token = responseObject[@"access_token"];
        self.tokenID = responseObject[@"id_token"];
        
        // save this to the keychain if the service name is available.
        if (self.serviceName != nil) {
            
            OSStatus status;
            
            if (self.token) {
                status = [self setKeychainItem:self.username data:self.token];
            }
            
            if (self.tokenID) {
                status = [self setKeychainItem:[self.username stringByAppendingString:@"-ID"] data:self.tokenID];
            }
            
        }
        
        if (self->_state) {
            self->_state = nil;
        }
        
        if (successCB) {
            successCB();
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (self->_state) {
            self->_state = nil;
        }
       
        if (errorCB) {
            errorCB(error);
        }
        
    }];
    
}

#pragma mark - Overrides

- (NSDictionary *)commonParameters {
    return @{};
}

- (NSString *)oAuthVersion
{
    return @"2.0";
}

- (void)setBaseURL:(NSURL *)baseURL {
    
    if (_baseURL == nil || [_baseURL isEqual:baseURL] == NO) {
        _baseURL = baseURL;
        
        self.session.baseURL = baseURL;
    }
    
}

#pragma mark - HTTP

- (NSURLSessionTask *)GET:(NSString * _Nonnull)URI
               parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{
    
    return [self.session GET:URI parameters:params success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)POST:(NSString * _Nonnull)URI
                parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{

    return [self.session POST:URI parameters:params success:successCB error:errorCB];

}

- (NSURLSessionTask *)POST:(NSString * _Nonnull)URI
               queryParams:(NSDictionary * _Nullable)query
                parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{

    return [self.session POST:URI queryParams:query parameters:params success:successCB error:errorCB];

}

- (NSURLSessionTask *)PUT:(NSString * _Nonnull)URI
               parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{

    return [self.session PUT:URI parameters:params success:successCB error:errorCB];

}

- (NSURLSessionTask *)PUT:(NSString * _Nonnull)URI
              queryParams:(NSDictionary * _Nullable)query
               parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{

    return [self.session PUT:URI queryParams:query parameters:params success:successCB error:errorCB];

}

- (NSURLSessionTask *)PATCH:(NSString * _Nonnull)URI
                 parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{

    return [self.session PATCH:URI parameters:params success:successCB error:errorCB];

}

- (NSURLSessionTask *)DELETE:(NSString * _Nonnull)URI
                  parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{

    return [self.session GET:URI parameters:params success:successCB error:errorCB];

}

- (NSURLSessionTask *)HEAD:(NSString * _Nonnull)URI
                parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{

    return [self.session HEAD:URI parameters:params success:successCB error:errorCB];

}


- (NSURLSessionTask *)OPTIONS:(NSString * _Nonnull)URI
                   parameters:(NSDictionary * _Nonnull)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB
{

    return [self.session OPTIONS:URI parameters:params success:successCB error:errorCB];

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

- (NSURLQueryItem *)queryItemForKey:(NSString *)key from:(NSArray <NSURLQueryItem *> *)items {
    
    __block NSURLQueryItem *item = nil;
    
    if (key && items && items.count) {
        
        [items enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([obj.name isEqualToString:key]) {
                item = obj;
                *stop = YES;
            }
            
        }];
        
    }
    
    return item;
    
}

- (NSString *)valueForQueryItemKey:(NSString *)key from:(NSArray <NSURLQueryItem *> *)items {
    
    NSURLQueryItem *item = [self queryItemForKey:key from:items];
    
    if (item) {
        return item.value;
    }
    
    return nil;
    
}

#pragma mark - Keychain

- (NSString *)username {
    return (self.accountName ?: (self.tokenID ?: @""));
}

/*
 Get the password for this service name. If there is no password on the keychain for this service,
 this method will return an error.
 */
- (NSString *)getKeychainItem:(NSString *)key itemRef:(CFTypeRef)itemRef {
    
    OSStatus status;
    
    NSString *username = (key ?: self.username);
    
    NSDictionary *query = @{(__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassInternetPassword,
                            (__bridge NSString *)kSecAttrServer: self.baseURL,
                            (__bridge NSString *)kSecMatchLimit: (NSString *)kSecMatchLimitOne,
                            (__bridge NSString *)kSecReturnAttributes: @(NO),
                            (__bridge NSString *)kSecReturnData: @(YES),
                            (__bridge NSString *)kSecAttrLabel: @"oAuth2Token"
                            };
    
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &itemRef);
    
    if (status == errSecItemNotFound) {
        return nil;
    }
    
    if (status != errSecSuccess) {
#ifdef DEBUG
        NSLog(@"Error fetching sec item:%@", username);
#endif
        return nil;
    }
    
    NSDictionary *matchingItem = (__bridge NSDictionary *)itemRef;
    
    NSData *passwordData = matchingItem[(__bridge NSString *)kSecValueData];
    
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    
    NSString *account = matchingItem[(__bridge NSString *)kSecAttrAccount];
    
    if ([account isEqualToString:username]) {
        return password;
    }
    
    return nil;
    
}

- (NSString *)getKeychainItem:(NSString *)key {
    
    return [self getKeychainItem:key itemRef:nil];
    
}

- (OSStatus)setKeychainItem:(NSString *)key data:(NSString *)data {
    
    NSData * password = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *query = @{(__bridge NSString *)kSecClass: (__bridge NSString *)kSecClassInternetPassword,
                            (__bridge NSString *)kSecAttrAccount: key,
                            (__bridge NSString *)kSecAttrServer: self.serviceName,
                            (__bridge NSString *)kSecValueData: password,
                            (__bridge NSString *)kSecAttrLabel: @"oAuth2Token"
                            };
    
    CFTypeRef itemRef;
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, &itemRef);
    
    if (status != errSecSuccess) {
#ifdef DEBUG
        NSLog(@"Error adding sec item:%@", key);
#endif
    }
    
    return status;
    
}

@end
