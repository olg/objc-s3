//
//  S3OperationQueue.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 04/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h";

@interface S3OperationQueue : NSObject <S3OperationDelegate> {
	NSMutableArray* _operations;
	NSMutableArray* _currentOperations;
}

// Convenience methods to register object with NSNotificationCenter
// if the object supports the S3OperationQueueNotifications.
// Must call removeQueueListener before object is deallocated.
- (void)addQueueListener:(id)obj;
- (void)removeQueueListener:(id)obj;

- (void)logOperation:(id)op;
- (void)unlogOperation:(id)op;

- (NSMutableArray *)currentOperations;
- (void)removeFromCurrentOperations:(S3Operation*)op;
- (BOOL)addToCurrentOperations:(S3Operation*)op;

@end

@interface NSObject (S3OperationQueueNotifications)
- (void)s3OperationStateDidChange:(NSNotification *)notification;
- (void)s3OperationDidFail:(NSNotification *)notification;
- (void)s3OperationDidFinish:(NSNotification *)notification;
@end

/* Notifications */
extern NSString *S3OperationStateDidChangeNotification;
extern NSString *S3OperationDidFailNotification;
extern NSString *S3OperationDidFinishNotification;

/* Notification UserInfo Keys */
extern NSString *S3OperationObjectKey;