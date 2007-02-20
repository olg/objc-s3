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

// These keys are also used in nib file, for bindings

#define FILEDATA_PATH @"path"
#define FILEDATA_KEY  @"key"
#define FILEDATA_TYPE @"mime"
#define FILEDATA_SIZE @"size"

typedef enum _S3OperationState {
	S3OperationDone = 1,
	S3OperationError = 2,
	S3OperationActive = 3,
	S3OperationPending = 4
} S3OperationState;

@class S3Operation;

@protocol S3OperationDelegate
-(void)operationStateDidChange:(S3Operation*)o;
-(void)operationDidFinish:(S3Operation*)o;
-(void)operationDidFail:(S3Operation*)o;
@end


@interface S3Operation : NSObject {
	NSString* _status;
	NSError* _error;
	NSObject<S3OperationDelegate>* _delegate;	
	BOOL _active;
	S3OperationState _state;
}

- (id)initWithDelegate:(id)delegate;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (BOOL)active;
- (void)setActive:(BOOL)flag;
- (BOOL)operationSuccess;
- (NSError *)error;
- (void)setError:(NSError *)anError;
- (NSString *)status;
- (void)setStatus:(NSString *)aStatus;
- (void)stop:(id)sender;
- (void)start:(id)sender;
- (S3OperationState)state;
- (void)setState:(S3OperationState)aState;

@end


