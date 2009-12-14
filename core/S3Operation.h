//
//  S3Operation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/1/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>

#define S3_ERROR_RESOURCE_KEY @"ResourceKey"
#define S3_ERROR_HTTP_STATUS_KEY @"HTTPStatusKey"
#define S3_ERROR_DOMAIN @"S3"
#define S3_ERROR_CODE_KEY @"S3ErrorCode"

typedef enum _S3OperationState {
    S3OperationPending = 0,
    S3OperationPendingRetry = 2,
    S3OperationActive = 3,
    S3OperationCanceled = 4,
    S3OperationRequiresRedirect = 5,
    S3OperationDone = 6,
    S3OperationError = 7
} S3OperationState;

@class S3ConnectionInfo;
@class S3Bucket;
@class S3Object;
@class S3Operation;
@class S3TransferRateCalculator;

@protocol S3OperationDelegate
- (void)operationInformationalStatusDidChange:(S3Operation *)o;
- (void)operationInformationalSubStatusDidChange:(S3Operation *)o;
- (void)operationStateDidChange:(S3Operation *)o;
@end

@interface NSObject (S3OperationDelegate)
- (NSUInteger)operationQueuePosition:(S3Operation *)o;
@end

@interface S3Operation : NSObject {
    NSObject <S3OperationDelegate> *delegate;
    
    S3ConnectionInfo *connectionInfo;
    
    NSCalendarDate *_date;
    
    
    CFReadStreamRef httpOperationReadStream;
    
    NSDictionary *requestHeaders;
    NSDictionary *responseHeaders;
    NSNumber *responseStatusCode;
    NSData *responseData;
    NSFileHandle *responseFileHandle;
    
    S3OperationState state;
    NSString *informationalStatus;
    NSString *informationalSubStatus;
    
    BOOL allowsRetry;
    
    S3TransferRateCalculator *rateCalculator;
    
    NSInteger queuePosition;
    
    NSError *error;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)aConnectionInfo;

@property(nonatomic, assign) id delegate;
@property(nonatomic, assign) BOOL allowsRetry;

@property(nonatomic, assign, readwrite) S3OperationState state;
@property(nonatomic, retain, readwrite) S3ConnectionInfo *connectionInfo;
@property(nonatomic, retain, readwrite) NSString *informationalStatus;
@property(nonatomic, retain, readwrite) NSString *informationalSubStatus;

@property(nonatomic, retain, readwrite) NSDictionary *requestHeaders;

@property(nonatomic, copy, readwrite) NSCalendarDate *date;
@property(nonatomic, copy, readwrite) NSDictionary *responseHeaders;
@property(nonatomic, copy, readwrite) NSNumber *responseStatusCode;
@property(nonatomic, copy, readwrite) NSData *responseData;
@property(nonatomic, retain, readwrite) NSFileHandle *responseFileHandle;
@property(nonatomic, copy, readwrite) NSError *error;
@property(nonatomic, assign, readwrite) NSInteger queuePosition;

- (BOOL)isRequestOnService;

- (void)start:(id)sender;
- (void)stop:(id)sender;

- (BOOL)active;
- (BOOL)success;

- (NSURL *)url;

- (NSError*)errorFromHTTPRequestStatus:(int)status data:(NSData*)data;

// This method must be implemented by subclasses.
- (NSString *)requestHTTPVerb; // May NOT return nil. Must comply with HTTP 1.1 available verbs in rfc 2616 Sec 5.1.1


// All the following methods are optionally implemented by subclasses

- (NSString *)bucketName; // May return nil.
- (NSString *)key; // May return nil.
- (NSDictionary *)requestQueryItems; // May return nil.

// -additionalHTTPRequestHeaders: is for subclassers to add additional
// HTTP headers to the request than is normally generated.
- (NSDictionary *)additionalHTTPRequestHeaders; // May return nil. Allows subclassers to return custom headers.

// -requestBodyContentMimeType and -requestBodyContentLength provide
// optional information for the request body content. These items can
// be placed in the -additionalHTTPRequestHeaders:. If they are not in
// the -additionalHTTPRequestHeaders: the request will try to retrieve
// the values from these methods as appropriate.
- (NSString *)requestBodyContentMD5;
- (NSString *)requestBodyContentType;
- (NSUInteger)requestBodyContentLength;

// -requestBodyContentData and -requestBodyContentFilePath provide 
// the request body data for the operation if needed. If used, only
// one method should return non-nil. The Superclass will only use the
// first non-nil return it sees.
- (NSData *)requestBodyContentData;
- (NSString *)requestBodyContentFilePath;

// -responseBodyContentFilePath should be a writeable file path that
// the operation can use to write the response body content instead
// of storing the response data in the operation.
- (NSString *)responseBodyContentFilePath;
- (long long)responseBodyContentExepctedLength;

@end


