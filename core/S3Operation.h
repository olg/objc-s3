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
	NSString* _status;
	NSError* _error;
	NSObject<S3OperationDelegate>* _delegate;	
	BOOL _active;
}

- (id)initWithDelegate:(id)delegate;
- (BOOL)active;
- (void)setActive:(BOOL)flag;
- (BOOL)operationSuccess;
- (NSError *)error;
- (void)setError:(NSError *)anError;
- (NSString *)status;
- (void)setStatus:(NSString *)aStatus;
- (void)stop:(id)sender;

@end

@interface S3NSURLConnectionOperation : S3Operation {
	NSHTTPURLResponse* _response;
	NSURLRequest* _request;
	NSURLConnection* _connection;
	NSMutableData* _data;
}

-(id)initWithRequest:(NSURLRequest*)request delegate:(id)delegate;

@end
