//
//  S3ConnectionInfo.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/2/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ConnectionInfo.h"
#import "S3MutableConnectionInfo.h"

#import "S3HTTPUrlBuilder.h"
#import "S3Operation.h"
#import "S3Object.h"
#import "S3Extensions.h"
#import <Security/Security.h>


NSString *S3DefaultHostString = @"s3.amazonaws.com";
NSInteger S3DefaultInsecurePortInteger = 80;
NSInteger S3DefaultSecurePortInteger = 443;
NSString *S3InsecureHTTPProtocolString = @"http";
NSString *S3SecureHTTPProtocolString = @"https";

//XAMZACL
NSString *S3HeaderACLString = @"x-amz-acl";
NSString *S3HeaderPrefixString = @"x-amz";

@interface S3ConnectionInfo (S3MutableConnectionInfoExtensionMethods)

- (void)setDelegate:(id)delegate;
- (void)setUserInfo:(NSDictionary *)userInfo;
- (void)setSecureConnection:(BOOL)secure;
- (void)setPortNumber:(int)portNumber;
- (void)setVirtuallyHosted:(BOOL)yesOrNo;
- (void)setHostEndpoint:(NSString *)host;

@end

@implementation S3ConnectionInfo

- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(int)portNumber virtuallyHosted:(BOOL)virtuallyHosted hostEndpoint:(NSString *)host
{
    self = [super init];
    if (self != nil) {
        if (delegate == nil) {
            [self release];
            return nil;
        }        
        [self setDelegate:delegate];
        [self setUserInfo:userInfo];
        [self setSecureConnection:secureConnection];
        [self setPortNumber:portNumber];
        [self setVirtuallyHosted:virtuallyHosted];
        [self setHostEndpoint:host];
    }
    return self;
}

- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(int)portNumber virtuallyHosted:(BOOL)virtuallyHosted
{
    return [self initWithDelegate:delegate userInfo:userInfo secureConnection:secureConnection portNumber:portNumber virtuallyHosted:virtuallyHosted hostEndpoint:S3DefaultHostString];
}

- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection portNumber:(int)portNumber
{
    return [self initWithDelegate:delegate userInfo:userInfo secureConnection:secureConnection portNumber:portNumber virtuallyHosted:YES];
}

- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo secureConnection:(BOOL)secureConnection
{
    return [self initWithDelegate:delegate userInfo:userInfo secureConnection:secureConnection portNumber:0];
}

- (id)initWithDelegate:(id)delegate userInfo:(id)userInfo
{
    return [self initWithDelegate:delegate userInfo:userInfo secureConnection:NO];
}

- (id)initWithDelegate:(id)delegate
{
    return [self initWithDelegate:delegate userInfo:nil];    
}

- (id)init
{
    return [self initWithDelegate:nil];
}

- (void)dealloc
{
    [self setUserInfo:nil];
    [self setHostEndpoint:nil];
    
	[super dealloc];
}

// A delegate is required
- (void)setDelegate:(id)delegate;
{
    _delegate = delegate;
}

- (id)delegate
{
    return _delegate;
}

// Insecure by default
// Resets the port number using setPortNumber:
// to default based on the value set.
- (void)setSecureConnection:(BOOL)secure
{
    if (secure == NO) {
        [self setPortNumber:S3DefaultInsecurePortInteger];
    } else {
        [self setPortNumber:S3DefaultSecurePortInteger];
    }
    _secure = secure;
}

- (BOOL)secureConnection
{
    return _secure;
}

// Uses default port for either secure or
// insecure connection unless set after
// secure connection is set.
- (void)setPortNumber:(int)portNumber
{
    if (portNumber == 0) {
        [self setSecureConnection:[self secureConnection]];
        return;
    }
    _portNumber = portNumber;
}

- (int)portNumber
{
    return _portNumber;
}

- (void)setHostEndpoint:(NSString *)host
{
    host = [host copy];
    [_host release];
    _host = host;
}

- (NSString *)hostEndpoint
{
    return _host;
}

- (void)setVirtuallyHosted:(BOOL)yesOrNo
{
    _virtuallyHosted = yesOrNo;
}

- (BOOL)virtuallyHosted
{
    return _virtuallyHosted;
}

- (void)setUserInfo:(NSDictionary *)userInfo
{
    [userInfo retain];
    [_userInfo release];
    _userInfo = userInfo;
}

- (NSDictionary *)userInfo
{
    return _userInfo;
}

// Create a CFHTTPMessageRef from an operation; object returned has a retain count of 1
// and must be released by the receiver when finished using the object.
- (CFHTTPMessageRef)newCFHTTPMessageRefFromOperation:(S3Operation *)operation
{
    // This process can not go forward without a delegate
    if ([self delegate] == nil) {
        return NULL;
    }

    // Build string to sign

    // HTTP Verb + '\n' +
    // Content MD5 + '\n' +
    // Content Type + '\n' +
    // Date + '\n' +
    // CanonicalizedAmzHeaders +
    // CanonicalizedResourse;
    
    NSMutableString *stringToSign = [NSMutableString string];
    [stringToSign appendFormat:@"%@\n", ([operation requestHTTPVerb] ? [operation requestHTTPVerb] : @"")];
    
    NSString *md5 = [[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentMD5Key];
    if (md5 == nil) {
        md5 = [operation requestBodyContentMD5];
    }
    [stringToSign appendFormat:@"%@\n", (md5 ? md5 : @"")];
    
    NSString *contentType = [[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentTypeKey];
    if (contentType == nil) {
        contentType = [operation requestBodyContentType];
    }
    [stringToSign appendFormat:@"%@\n", (contentType ? contentType : @"")];
    
    [stringToSign appendFormat:@"%@\n", [[operation date] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"]];
    
    // Work out the Canonicalized Amz Headers
    NSEnumerator *e = [[[[operation additionalHTTPRequestHeaders] allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    NSString *key = nil;
	while (key = [e nextObject])
	{
		id object = [[operation additionalHTTPRequestHeaders] objectForKey:key];
        NSString *lowerCaseKey = [key lowercaseString];
		if ([key hasPrefix:S3HeaderPrefixString]) {
			[stringToSign appendFormat:@"%@:%@\n", lowerCaseKey, object];            
        }
	}    
    
    // Work out the Canonicalized Resource
    NSURL *requestURL = [operation url];
    NSString *requestQuery = [requestURL query];
    NSString *requestPath = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[requestURL path], NULL, (CFStringRef)@"[]#%?,$+=&@:;()'*!", kCFStringEncodingUTF8) autorelease];
    NSString *absoluteString = [requestURL absoluteString];
    if (requestQuery != nil) {
        NSString *withoutQuery = [absoluteString stringByReplacingOccurrencesOfString:requestQuery withString:@""];
        if ([requestPath hasSuffix:@"/"] == NO && [withoutQuery hasSuffix:@"/?"] == YES) {
            requestPath = [NSString stringWithFormat:@"%@/", requestPath];            
        }
    } else if ([requestPath hasSuffix:@"/"] == NO && [absoluteString hasSuffix:@"/"] == YES) {
        requestPath = [NSString stringWithFormat:@"%@/", requestPath];
    }
    
    if (([operation isRequestOnService] == NO) && ([self virtuallyHosted] == YES) && [operation virtuallyHostedCapable]) {
        requestPath = [NSString stringWithFormat:@"/%@%@", [operation bucketName], requestPath];
    }
    
    [stringToSign appendString:requestPath];
    
    if ([[requestURL query] hasPrefix:@"acl"]) {
        [stringToSign appendString:@"?acl"];
    } else if ([[requestURL query] hasPrefix:@"torrent"]) {
        [stringToSign appendString:@"?torrent"];        
    } else if ([[requestURL query] hasPrefix:@"location"]) {
        [stringToSign appendString:@"?location"];        
    } else if ([[requestURL query] hasPrefix:@"logging"]) {
        [stringToSign appendString:@"?logging"];
    }
    
    CFHTTPMessageRef httpRequest = NULL;
    NSString *authorization = nil;
    
    // Sign or send this string off to be signed.
    // Check first to see if the delegate implements
    // - (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;
    // - (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;
    if ([[self delegate] respondsToSelector:@selector(accessKeyForConnectionInfo:)] && [[self delegate] respondsToSelector:@selector(secretAccessKeyForConnectionInfo:)]) {
        NSString *accessKey = [[self delegate] accessKeyForConnectionInfo:self];
        NSString *secretAccessKey = [[self delegate] secretAccessKeyForConnectionInfo:self];
        
        if (accessKey == nil || secretAccessKey == nil) {
            return NULL;
        }
        
        NSString *signature = [[[stringToSign dataUsingEncoding:NSUTF8StringEncoding] sha1HMacWithKey:secretAccessKey] encodeBase64];
        secretAccessKey = nil;
        authorization = [NSString stringWithFormat:@"AWS %@:%@", accessKey, signature];
        
    } else if ([[self delegate] respondsToSelector:@selector(connectionInfo:authorizationHeaderForRequestHeader:)]) {
        authorization = [[self delegate] connectionInfo:self authorizationHeaderForRequestHeader:stringToSign];
    } else {
        // The required delegate methods are not present.
        return NULL;
    }
    
    httpRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)[operation requestHTTPVerb], (CFURLRef)requestURL, kCFHTTPVersion1_1);
    e = [[[operation additionalHTTPRequestHeaders] allKeys] objectEnumerator];
    key = nil;
	while (key = [e nextObject])
	{
		id object = [[operation additionalHTTPRequestHeaders] objectForKey:key];
        CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)key, (CFStringRef)[NSString stringWithFormat:@"%@", object]);
	}
    
    if ([[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentLengthKey] == nil) {
        NSNumber *contentLength = [NSNumber numberWithLongLong:[operation requestBodyContentLength]];
        CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)S3ObjectMetadataContentLengthKey, (CFStringRef)[contentLength stringValue]);
    }
    
    if ([[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentTypeKey] == nil) {
        if (contentType != nil) {
            CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)S3ObjectMetadataContentTypeKey, (CFStringRef)contentType);
        }
    }
    
    if ([[operation additionalHTTPRequestHeaders] objectForKey:S3ObjectMetadataContentMD5Key] == nil) {
        if (md5 != nil) {
            CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)S3ObjectMetadataContentMD5Key, (CFStringRef)md5);
        }
    }
    
    // Add the "Expect: 100-continue" header
    CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)@"Expect", (CFStringRef)@"100-continue");
    
    CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)@"Date", (CFStringRef)[[operation date] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"]);
    CFHTTPMessageSetHeaderFieldValue(httpRequest, (CFStringRef)@"Authorization", (CFStringRef)authorization);

    
    return httpRequest;
}

#pragma mark -
#pragma mark Copying Protocol Methods

- (id)copyWithZone:(NSZone *)zone
{
    S3ConnectionInfo *newObject = [[S3ConnectionInfo allocWithZone:zone] initWithDelegate:[self delegate]
                                                                                 userInfo:[self userInfo]
                                                                         secureConnection:[self secureConnection]
                                                                               portNumber:[self portNumber]
                                                                          virtuallyHosted:[self virtuallyHosted]
                                                                             hostEndpoint:[self hostEndpoint]];
    return newObject;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    S3MutableConnectionInfo *newObject = [[S3MutableConnectionInfo allocWithZone:zone] initWithDelegate:[self delegate] 
                                                                                               userInfo:[self userInfo] 
                                                                                       secureConnection:[self secureConnection] 
                                                                                             portNumber:[self portNumber] 
                                                                                        virtuallyHosted:[self virtuallyHosted] 
                                                                                           hostEndpoint:[self hostEndpoint]];
    return newObject;
}

#pragma mark -
#pragma mark Equality Methods

- (BOOL)isEqual:(id)anObject
{
    if (anObject && [anObject isKindOfClass:[S3ConnectionInfo class]]) {
        if ([anObject delegate] == [self delegate] && 
            (([anObject userInfo] == nil && [self userInfo] == nil) || 
             [[anObject userInfo] isEqual:[self userInfo]]) &&
            [anObject secureConnection] == [self secureConnection] &&
            [anObject portNumber] == [self portNumber] &&
            [anObject virtuallyHosted] == [self virtuallyHosted] &&
            (([anObject hostEndpoint] == nil && [self hostEndpoint] == nil) || 
             [[anObject hostEndpoint] isEqual:[self hostEndpoint]])) {
            return YES;
        }
    }
    
    return NO;
}

- (NSUInteger)hash
{
    NSUInteger value = 0;
    
    value += value * 37 + (NSUInteger)[self delegate];
    value += value * 37 + [[self userInfo] hash];
    value += value * 37 + ([self secureConnection] ? 1 : 2);

// For the most part these are redundent, but can be uncommented if deemed worthy later.
//    value += value * 37 + [self portNumber];
//    value += value * 37 + ([self virtuallyHosted] ? 1 : 2);
//    value += value * 37 + [[self hostEndpoint] hash];

    return value;
}

#pragma mark -
#pragma mark Description Method

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %#x -\n delegate:%#x\n userInfo:%@\n secureConnection:%d\n portNumber:%d\n virtuallyHosted:%d\n hostEndpoint:%@\n>", [self class], self, [self delegate], [self userInfo], [self secureConnection], [self portNumber], [self virtuallyHosted], [self hostEndpoint]];
}

@end
