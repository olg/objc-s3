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

typedef enum _S3OperationState {
	S3OperationDone = 1,
	S3OperationError = 2,
	S3OperationProcessing = 3
} S3OperationState;

@class S3Operation;

@protocol S3OperationDelegate
// Optional:
-(void)operationStateChange:(S3Operation*)o;
-(void)operationDidFinish:(S3Operation*)o;
-(void)operationDidFail:(S3Operation*)o;
@end


@interface S3Operation : NSObject {
	NSHTTPURLResponse* _response;
	NSURLRequest* _request;
	NSString* _status;
	NSError* _error;
	NSObject<S3OperationDelegate>* _delegate;	
	BOOL _active;
}

- (BOOL)active;
- (void)setActive:(BOOL)flag;
- (BOOL)operationSuccess;
- (NSHTTPURLResponse *)response;
- (void)setResponse:(NSHTTPURLResponse *)aResponse;
- (NSError *)error;
- (void)setError:(NSError *)anError;
- (NSString *)status;
- (void)setStatus:(NSString *)aStatus;
- (id)initWithRequest:(NSURLRequest*)connection delegate:(id)delegate;
- (void)stop:(id)sender;

@end

@interface S3NSURLConnectionOperation : S3Operation {
	NSURLConnection* _connection;
	NSMutableData* _data;
}

@end
