//
//  S3ConnectionInfo.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/2/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>

@class S3Operation;

@interface S3ConnectionInfo : NSObject <NSCopying, NSMutableCopying> {
    id _delegate;               // A delegate is required.
    NSDictionary *_userInfo;    // Contributes to equality.
    BOOL _secure;               // Insecure by default.
    int _portNumber;            // Uses default port if 0 depending on secureConnection state.
    BOOL _virtuallyHosted;      // Determines how connection requests are formed.
    NSString *_host;            // For a host other than the default Amazon S3 host endpoint.
}

- (id)initWithDelegate:(id)delegate;
- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo;
- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection;
- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(int)portNumber;
- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(int)portNumber virtuallyHosted:(BOOL)virtuallyHosted;
- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(int)portNumber virtuallyHosted:(BOOL)virtuallyHosted hostEndpoint:(NSString *)host;

- (id)delegate;
- (BOOL)secureConnection;
- (int)portNumber;
- (NSString *)hostEndpoint;
- (BOOL)virtuallyHosted;
- (NSDictionary *)userInfo;

// Create a CFHTTPMessageRef from an operation; object returned has a retain count of 1
// and must be released by the caller when finished using the object.
- (CFHTTPMessageRef)newCFHTTPMessageRefFromOperation:(S3Operation *)operation;

@end

@interface NSObject (S3ConnectionInfoDelegate)

// Required for S3ConnectionInfo to handle authorization of requests itself
- (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;
- (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;

// Required if the above delegate methods are not present.
// Should return a valid S3 Authentication Header value.
// (See Amazon Simple Storage Service 'Authenticating REST Requests' for how to sign and form a valid header value)
- (NSString *)connectionInfo:(S3ConnectionInfo *)connection authorizationHeaderForRequestHeader:(NSString *)requestHeaderToSign;

@end