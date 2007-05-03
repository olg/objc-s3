//
//  S3Operation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/1/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define S3_ERROR_RESOURCE_KEY @"ResourceKey"
#define S3_ERROR_HTTP_STATUS_KEY @"HTTPStatusKey"
#define S3_ERROR_DOMAIN @"S3"
#define S3_ERROR_CODE_KEY @"S3ErrorCode"

// These keys are also used in nib file, for bindings

#define FILEDATA_PATH @"path"
#define FILEDATA_KEY  @"key"
#define FILEDATA_TYPE @"mime"
#define FILEDATA_SIZE @"size"

typedef enum _S3OperationState {
	S3OperationDone = 1,
	S3OperationError = 2,
    S3OperationCanceled = 3,
	S3OperationActive = 4,
	S3OperationPending = 5,
    S3OperationPendingRetry = 6
} S3OperationState;

@class S3Operation;
@class S3Connection;

@protocol S3OperationDelegate
- (void)operationStateDidChange:(S3Operation *)o;
- (void)operationDidFinish:(S3Operation *)o;
- (void)operationDidFail:(S3Operation *)o;
@end


@interface S3Operation : NSObject {
    S3Connection *_connection;
	NSString *_status;
	NSError *_error;
	NSObject<S3OperationDelegate> *_delegate;	
	S3OperationState _state;
    BOOL _allowsRetry;
}

- (id)init;

- (id)delegate;
- (void)setDelegate:(id)delegate;
- (BOOL)active;
- (BOOL)operationSuccess;
- (NSError *)error;
- (void)setError:(NSError *)anError;
- (NSString *)status;
- (void)setStatus:(NSString *)aStatus;
- (void)stop:(id)sender;
- (void)start:(id)sender;
- (S3OperationState)state;
- (void)setState:(S3OperationState)aState;
- (BOOL)allowsRetry;
- (void)setAllowsRetry:(BOOL)yn;

@end


