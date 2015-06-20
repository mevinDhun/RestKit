//
//  RKHTTPRequestOperation.m
//  RestKit
//
//  Created by Blake Watters on 8/7/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKHTTPRequestOperation.h"
#import "RKLog.h"
#import "lcl_RK.h"
#import "RKHTTPUtilities.h"
#import "RKMIMETypes.h"

typedef enum {
    RKOperationPausedState      = -1,
    RKOperationReadyState       = 1,
    RKOperationExecutingState   = 2,
    RKOperationFinishedState    = 3,
} _RKOperationState;

typedef signed short RKOperationState;

extern NSString * const RKErrorDomain;

static NSString * const kRKNetworkingLockName = @"com.restkit.networking.operation.lock";

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetwork

NSString *RKStringFromIndexSet(NSIndexSet *indexSet); // Defined in RKResponseDescriptor.m

static BOOL RKResponseRequiresContentTypeMatch(NSHTTPURLResponse *response, NSURLRequest *request)
{
    if (RKRequestMethodFromString(request.HTTPMethod) == RKRequestMethodHEAD) return NO;
    if ([RKStatusCodesOfResponsesWithOptionalBodies() containsIndex:response.statusCode]) return NO;
    return YES;
}

const NSMutableIndexSet *acceptableStatusCodes;
const NSMutableSet *acceptableContentTypes;

@interface RKHTTPRequestOperation ()
@property (readwrite, nonatomic, assign) RKOperationState state;
@property (readwrite, nonatomic, strong) NSError *rkHTTPError;
@property (readwrite, nonatomic, strong) id<RKHTTPClient> HTTPClient;
@property (readwrite, nonatomic, strong) NSURLRequest *request;
@property (readwrite, nonatomic, strong) NSHTTPURLResponse *response;
@property (readwrite, nonatomic, strong) NSError *error;
@property (readwrite, nonatomic, strong) NSData *responseData;
@property (readwrite, nonatomic, strong) NSString *responseString;
@property (readwrite, nonatomic, strong) id responseObject;
@property (readwrite, nonatomic, strong) NSError *responseSerializationError;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) id operation;
@property (nonatomic) BOOL supportsSession;
@property (nonatomic, readwrite) BOOL isExecuting;
@property (nonatomic, readwrite) BOOL isFinished;

@end

@implementation RKHTTPRequestOperation

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest HTTPClient:(id<RKHTTPClient>)HTTPClient{
    
    NSParameterAssert(urlRequest);
    NSParameterAssert(HTTPClient);
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.isExecuting = NO;
    self.isFinished = NO;
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = kRKNetworkingLockName;
    self.request = urlRequest;
    self.HTTPClient = HTTPClient;
    
    self.state = RKOperationReadyState;
    
    return self;
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request
{
    return YES;
}
- (void)pause {
    if ([self isPaused] || [self isFinished] || [self isCancelled]) {
        return;
    }
    
    [self.lock lock];
    
    if ([self isExecuting]) {
        //Pause
    }
    
    self.state = RKOperationPausedState;
    
    [self.lock unlock];
}

- (BOOL)isPaused {
    return self.state == RKOperationPausedState;
}

- (void)resume {
    if (![self isPaused]) {
        return;
    }
    
    [self.lock lock];
    self.state = RKOperationReadyState;
    
    [self start];
    [self.lock unlock];
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == RKOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == RKOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == RKOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    [self.lock lock];
    if ([self isReady]) {
        self.state = RKOperationExecutingState;
        
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];

        [self.HTTPClient performRequest:self.request completionHandler:^(id responseObject, NSData *responseData, NSURLResponse *response, NSError *error) {
            
            self.responseData = responseData;
            self.responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            self.responseObject = responseObject;            
            self.response = (NSHTTPURLResponse*) response;
            self.error = error;
            [self finish];
        }];
    }
    [self.lock unlock];
}


- (void)finish {
    self.state = RKOperationFinishedState;
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [self willChangeValueForKey:@"isCancelled"];
        
        [super cancel];
        [self didChangeValueForKey:@"isCancelled"];
        
        // Cancel the connection on the thread it runs on to prevent race conditions
        
    }
    [self.lock unlock];
}


+ (NSIndexSet *)acceptableStatusCodes{
    if(!acceptableStatusCodes){
        acceptableStatusCodes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    
    return [acceptableStatusCodes copy];
}

+ (void)addAcceptableStatusCodes:(NSIndexSet *)statusCodes{
    [acceptableStatusCodes addIndexes:statusCodes];
}

- (BOOL)hasAcceptableStatusCode
{
    if (! self.response) return NO;
    NSUInteger statusCode = ([self.response isKindOfClass:[NSHTTPURLResponse class]]) ? (NSUInteger)[self.response statusCode] : 200;
    
    if(self.acceptableStatusCodes){
        return [self.acceptableStatusCodes containsIndex:statusCode];
    }
    
    return ![[self class] acceptableStatusCodes] || [[[self class] acceptableStatusCodes] containsIndex:statusCode];
}

+ (NSSet *)acceptableContentTypes{
    
    return [acceptableContentTypes copy];
}

+ (void)addAcceptableContentTypes:(NSSet *)contentTypes{
    
    if(!acceptableContentTypes){
        acceptableContentTypes = [NSMutableSet new];
    }
    
    [acceptableContentTypes unionSet:contentTypes];
}

- (BOOL)hasAcceptableContentType
{
    if (! self.response) return NO;
    if (!RKResponseRequiresContentTypeMatch(self.response, self.request)) return YES;
    NSString *contentType = [self.response MIMEType] ?: @"application/octet-stream";

    if(self.acceptableContentTypes){
        return RKMIMETypeInSet(contentType, self.acceptableContentTypes);
    }
    
    // Any HTTP/1.1 message containing an entity-body SHOULD include a Content-Type header field defining the media type of that body. If and only if the media type is not given by a Content-Type field, the recipient MAY attempt to guess the media type via inspection of its content and/or the name extension(s) of the URI used to identify the resource. If the media type remains unknown, the recipient SHOULD treat it as type "application/octet-stream".
    // See http://www.w3.org/Protocols/rfc2616/rfc2616-sec7.html
    if (!contentType) {
        contentType = @"application/octet-stream";
    }
    
    return ![[self class] acceptableContentTypes] || [[[self class] acceptableContentTypes] containsObject:contentType];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)decoder {
    NSURLRequest *request = [decoder decodeObjectOfClass:[NSURLRequest class] forKey:NSStringFromSelector(@selector(request))];
    id<RKHTTPClient> HTTPClient = [decoder decodeObjectOfClass:[NSURLRequest class] forKey:NSStringFromSelector(@selector(HTTPClient))];
    
    self = [self initWithRequest:request HTTPClient:HTTPClient];
    if (!self) {
        return nil;
    }
    
    self.response = [decoder decodeObjectOfClass:[NSHTTPURLResponse class] forKey:NSStringFromSelector(@selector(response))];
    self.error = [decoder decodeObjectOfClass:[NSError class] forKey:NSStringFromSelector(@selector(error))];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [self pause];
    
    [coder encodeObject:self.request forKey:NSStringFromSelector(@selector(request))];
    [coder encodeObject:self.HTTPClient forKey:NSStringFromSelector(@selector(HTTPClient))];

    [coder encodeObject:self.response forKey:NSStringFromSelector(@selector(response))];
    [coder encodeObject:self.error forKey:NSStringFromSelector(@selector(error))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
//    AFURLConnectionOperation *operation = [(AFURLConnectionOperation *)[[self class] allocWithZone:zone] initWithRequest:self.request];
//    
//    operation.uploadProgress = self.uploadProgress;
//    operation.downloadProgress = self.downloadProgress;
//    operation.authenticationChallenge = self.authenticationChallenge;
//    operation.cacheResponse = self.cacheResponse;
//    operation.redirectResponse = self.redirectResponse;
//    operation.completionQueue = self.completionQueue;
//    operation.completionGroup = self.completionGroup;
//    
//    return operation;
}

- (void)setCompletionBlockWithSuccess:(void (^)(RKHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(RKHTTPRequestOperation *operation, NSError *error))failure{
    
    __weak typeof(self) weakSelf = self;
    self.completionBlock = ^{
        if (weakSelf.error) {
            if (failure) {
                dispatch_async(weakSelf.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                    failure(weakSelf, weakSelf.error);
                });
            }
        } else {
            if (success) {
                dispatch_async(weakSelf.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                    success(weakSelf, weakSelf.responseData);
                });
            }
        }
    };
}

@end
