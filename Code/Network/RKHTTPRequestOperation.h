//
//  RKHTTPRequestOperation.h
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

#import <Foundation/Foundation.h>
#import "RKHTTP.h"
#import "RKHTTPClient.h"

@protocol RKHTTPResponseSerialization;

/**
 The `RKHTTPRequestOperation` class is a subclass of `AFHTTPRequestOperation` for HTTP or HTTPS requests made by RestKit. It provides per-instance configuration of the acceptable status codes and content types and integrates with the `RKLog` system to provide detailed requested and response logging. Instances of `RKHTTPRequest` are created by `RKObjectRequestOperation` and its subclasses to HTTP requests that will be object mapped. When used to make standalone HTTP requests, `RKHTTPRequestOperation` instance behave identically to `AFHTTPRequestOperation` with the exception of emitting logging information.
 
 ## Determining Request Processability
 
 The `RKHTTPRequestOperation` class diverges from the behavior of `AFHTTPRequestOperation` in the implementation of `canProcessRequest`, which is used to determine if a request can be processed. Because `RKHTTPRequestOperation` handles Content Type and Status Code acceptability at the instance rather than the class level, it by default returns `YES` when sent a `canProcessRequest:` method. Subclasses are encouraged to implement more specific logic if constraining the type of requests handled is desired.
 */
@interface RKHTTPRequestOperation : NSOperation <NSSecureCoding, NSCopying>

@property (readonly, nonatomic) id<RKHTTPClient> HTTPClient;

///-----------------------------------------
/// @name Getting URL Connection Information
///-----------------------------------------

/**
 The request used by the operation's connection.
 */
@property (readonly, nonatomic, strong) NSURLRequest *request;

/**
 The last response received by the operation's connection.
 */
@property (readonly, nonatomic, strong) NSHTTPURLResponse *response;

/**
 The raw response data
 **/
@property (readonly, nonatomic, strong) NSData *responseData;

/**
 The raw response string
 **/
@property (readonly, nonatomic, strong) NSString *responseString;

/**
 The URL credential
 **/
@property (nonatomic, strong) NSURLCredential *credential;

/**
 Whether each `RKHTTPRequestOperation` created by `HTTPRequestOperationWithRequest:success:failure:` should accept an invalid SSL certificate.
 */
@property (nonatomic, assign) BOOL allowsInvalidSSLCertificate;

/**
 Default SSL pinning mode for each `RKHTTPRequestOperation` created by `HTTPRequestOperationWithRequest:success:failure:`.
 */
@property (nonatomic, assign) RKSSLPinningMode SSLPinningMode;

/**
 The error, if any, that occurred in the lifecycle of the request.
 */
@property (readonly, nonatomic, strong) NSError *error;

///------------------------------------------------------------
/// @name Configuring Acceptable Status Codes and Content Types
///------------------------------------------------------------

/**
 The set of status codes which the operation considers successful.
 
 When `nil`, the acceptability of status codes is deferred to the superclass implementation.
 
 **Default**: `nil`
 */
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes;

/**
 The set of content types which the operation considers successful.
 
 The set may contain `NSString` or `NSRegularExpression` objects. When `nil`, the acceptability of content types is deferred to the superclass implementation.
 
 **Default**: `nil`
 */
@property (nonatomic, strong) NSSet *acceptableContentTypes;

/**
 Responses sent from the server in data tasks created with `dataTaskWithRequest:success:failure:` and run using the `GET` / `POST` / et al. convenience methods are automatically validated and serialized by the response serializer. By default, this property is set to an AFHTTPResponse serializer, which uses the raw data as its response object. The serializer validates the status code to be in the `2XX` range, denoting success. If the response serializer generates an error in `-responseObjectForResponse:data:error:`, the `failure` callback of the session task or request operation will be executed; otherwise, the `success` callback will be executed.
 
 @warning `responseSerializer` must not be `nil`. Setting a response serializer will clear out any cached value
 */
@property (nonatomic, strong) id <RKHTTPResponseSerialization> responseSerializer;

/**
 An object constructed by the `responseSerializer` from the response and response data. Returns `nil` unless the operation `isFinished`, has a `response`, and has `responseData` with non-zero content length. If an error occurs during serialization, `nil` will be returned, and the `error` property will be populated with the serialization error.
 */
@property (readonly, nonatomic, strong) id responseObject;

///-----------------------------------------------------------
/// @name Setting Completion Block Success / Failure Callbacks
///-----------------------------------------------------------

/**
 Initializes and returns a newly allocated operation object with a url connection configured with the specified url request.
 
 This is the designated initializer.
 
 @param urlRequest The request object to be used by the operation connection.
 */
- (instancetype)initWithRequest:(NSURLRequest *)urlRequest HTTPClient:(id<RKHTTPClient>)HTTPClient NS_DESIGNATED_INITIALIZER;

///----------------------------------
/// @name Pausing / Resuming Requests
///----------------------------------

/**
 Pauses the execution of the request operation.
 
 A paused operation returns `NO` for `-isReady`, `-isExecuting`, and `-isFinished`. As such, it will remain in an `NSOperationQueue` until it is either cancelled or resumed. Pausing a finished, cancelled, or paused operation has no effect.
 */
- (void)pause;

/**
 Whether the request operation is currently paused.
 
 @return `YES` if the operation is currently paused, otherwise `NO`.
 */
- (BOOL)isPaused;

/**
 Resumes the execution of the paused request operation.
 
 Pause/Resume behavior varies depending on the underlying implementation for the operation class. In its base implementation, resuming a paused requests restarts the original request. However, since HTTP defines a specification for how to request a specific content range, `AFHTTPRequestOperation` will resume downloading the request from where it left off, instead of restarting the original request.
 */
- (void)resume;

///------------------------------------------------------------
/// @name Managing Acceptable HTTP Status Codes & Content Types
///------------------------------------------------------------

/**
 Returns an `NSIndexSet` object containing the ranges of acceptable HTTP status codes. When non-`nil`, the operation will set the `error` property to an error in `AFErrorDomain`. See http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
 
 By default, this is the range 200 to 299, inclusive.
 */
+ (NSIndexSet *)acceptableStatusCodes;

/**
 Adds status codes to the set of acceptable HTTP status codes returned by `+acceptableStatusCodes` in subsequent calls by this class and its descendants.
 
 @param statusCodes The status codes to be added to the set of acceptable HTTP status codes
 */
+ (void)addAcceptableStatusCodes:(NSIndexSet *)statusCodes;

/**
 Returns an `NSSet` object containing the acceptable MIME types. When non-`nil`, the operation will set the `error` property to an error in `AFErrorDomain`. See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17
 
 By default, this is `nil`.
 */
+ (NSSet *)acceptableContentTypes;

/**
 Adds content types to the set of acceptable MIME types returned by `+acceptableContentTypes` in subsequent calls by this class and its descendants.
 
 @param contentTypes The content types to be added to the set of acceptable MIME types
 */
+ (void)addAcceptableContentTypes:(NSSet *)contentTypes;

///-----------------------------------------------------
/// @name Determining Whether A Request Can Be Processed
///-----------------------------------------------------

/**
 A Boolean value determining whether or not the class can process the specified request. For example, `AFJSONRequestOperation` may check to make sure the content type was `application/json` or the URL path extension was `.json`.
 
 @param urlRequest The request that is determined to be supported or not supported for this class.
 */
+ (BOOL)canProcessRequest:(NSURLRequest *)urlRequest;

/**
 The callback dispatch queue on success. If `NULL` (default), the main queue is used.
 
 The queue is retained while this operation is living
 */
@property (nonatomic, assign) dispatch_queue_t successCallbackQueue;

/**
 The callback dispatch queue on failure. If `NULL` (default), the main queue is used.
 
 The queue is retained while this operation is living
 */
@property (nonatomic, assign) dispatch_queue_t failureCallbackQueue;

/**
 Sets the `completionBlock` property with a block that executes either the specified success or failure block, depending on the state of the request on completion. If `error` returns a value, which can be caused by an unacceptable status code or content type, then `failure` is executed. Otherwise, `success` is executed.
 
 This method should be overridden in subclasses in order to specify the response object passed into the success block.
 
 @param success The block to be executed on the completion of a successful request. This block has no return value and takes two arguments: the receiver operation and the object constructed from the response data of the request.
 @param failure The block to be executed on the completion of an unsuccessful request. This block has no return value and takes two arguments: the receiver operation and the error that occurred during the request.
 */
- (void)setCompletionBlockWithSuccess:(void (^)(RKHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(RKHTTPRequestOperation *operation, NSError *error))failure;

@end
