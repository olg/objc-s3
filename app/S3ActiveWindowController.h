//
//  S3ActiveWindowController.h
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h"

@class S3Connection;

// This class handles all operation-based window by maintaining an active/pending operation queue

@interface S3ActiveWindowController : NSWindowController <S3OperationDelegate> {
	S3Connection* _connection;
	NSMutableArray* _currentOperations;
}

- (S3Connection *)connection;
- (void)setConnection:(S3Connection *)aConnection;

- (void)operationStateChange:(S3Operation*)o;
- (void)operationDidFail:(S3Operation*)o;
- (void)operationDidFinish:(S3Operation*)o;

- (NSMutableArray *)currentOperations;
- (void)setCurrentOperations:(NSMutableArray *)aCurrentOperations;
- (void)removeFromCurrentOperations:(S3Operation*)op;
- (void)addToCurrentOperations:(S3Operation*)op;

@end
