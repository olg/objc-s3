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
    S3OperationPendingRetry = 1,
    S3OperationActive = 2,
    S3OperationCanceled = 3,
    S3OperationDone = 4,
    S3OperationRequiresRedirect = 5,
    S3OperationError = 6,
    S3OperationRequiresVirtualHostingEnabled = 7,
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

    NSDictionary *operationInfo;
    
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

- (id)initWithConnectionInfo:(S3ConnectionInfo *)aConnectionInfo operationInfo:(NSDictionary *)anOperationInfo;
- (id)initWithConnectionInfo:(S3ConnectionInfo *)aConnectionInfo;

@property(readwrite, nonatomic, assign) id delegate;

// Connection information used by the operation.
@property(readonly, nonatomic, copy) S3ConnectionInfo *connectionInfo;

// operationInfo is used by subclasses to store their inital state
// information and therefore allows 'copying' the operation by:
// S3OperationSubclass *originalOperation;
// [[originalOperation class] initWithConnectionInfo:newConnectionInfo operationInfo:[originalOperation operationInfo]];
@property(readonly, nonatomic, copy) NSDictionary *operationInfo;

@property(readonly, nonatomic, assign) S3OperationState state;
@property(readonly, nonatomic, copy) NSString *informationalStatus;
@property(readonly, nonatomic, copy) NSString *informationalSubStatus;

@property(readonly, nonatomic, copy) NSCalendarDate *date;
@property(readonly, nonatomic, copy) NSDictionary *requestHeaders;
@property(readonly, nonatomic, copy) NSDictionary *responseHeaders;
@property(readonly, nonatomic, copy) NSNumber *responseStatusCode;
@property(readonly, nonatomic, copy) NSData *responseData;

- (BOOL)isRequestOnService;

- (void)start:(id)sender;
- (void)stop:(id)sender;

- (BOOL)active;
- (BOOL)success;

- (NSURL *)url;

- (NSError*)errorFromHTTPRequestStatus:(int)status data:(NSData*)data;

// These methods must be implemented by subclasses.
- (NSString *)kind; // A short human readable description of the operation.
- (NSString *)requestHTTPVerb; // May NOT return nil. Must comply with HTTP 1.1 available verbs in rfc 2616 Sec 5.1.1


// All the following methods are optionally implemented by subclasses
- (NSString *)bucketName; // May return nil.
- (NSString *)key; // May return nil.
- (NSDictionary *)requestQueryItems; // May return nil.
- (BOOL)virtuallyHostedCapable;

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

// -didInterpretStateForStreamHavingEndEncountered is implemented in rare instances
// by the subclass when the operation requires special knowledge to set the operation
// state. If the subclass wishes to set the state then it should dereference the state
// and set its value to what the new state value should be and YES should be returned.
// Returns NO by default by the base class.
- (BOOL)didInterpretStateForStreamHavingEndEncountered:(S3OperationState *)theState;
@end


