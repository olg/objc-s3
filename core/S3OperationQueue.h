//
//  S3OperationQueue.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 04/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class S3Operation;

@interface S3OperationQueue : NSObject {
	NSMutableArray* _operations;
	NSMutableArray* _currentOperations;
}

-(void)logOperation:(id)op;
-(void)unlogOperation:(id)op;

- (void)operationDidFail:(S3Operation*)o;
- (void)operationDidFinish:(S3Operation*)o;
- (void)operationStateChange:(S3Operation*)o;

- (NSMutableArray *)currentOperations;
- (void)removeFromCurrentOperations:(S3Operation*)op;
- (BOOL)addToCurrentOperations:(S3Operation*)op;

@end
