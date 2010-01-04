//
//  S3OperationQueue.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 04/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h"

@interface S3OperationQueue : NSObject <S3OperationDelegate> {
    id _delegate;
	NSMutableArray *_currentOperations;
    NSMutableArray *_activeOperations;
	NSTimer *_timer;
}

- (id)initWithDelegate:(id)delegate;

// Convenience methods to register object with NSNotificationCenter
// if the object supports the S3OperationQueueNotifications.
// Must call removeQueueListener before object is deallocated.
- (void)addQueueListener:(id)obj;
- (void)removeQueueListener:(id)obj;

- (BOOL)addToCurrentOperations:(S3Operation *)op;
- (NSArray *)currentOperations;

@end

@interface NSObject (S3OperationQueueDelegate)
- (int)maximumNumberOfSimultaneousOperationsForOperationQueue:(S3OperationQueue *)operationQueue;
@end

@interface NSObject (S3OperationQueueNotifications)
- (void)operationQueueOperationStateDidChange:(NSNotification *)notification;
- (void)operationQueueOperationInformationalStatusDidChangeNotification:(NSNotification *)notification;
- (void)operationQueueOperationInformationalSubStatusDidChangeNotification:(NSNotification *)notification;
@end

/* Notifications */
extern NSString *S3OperationQueueOperationStateDidChangeNotification;
extern NSString *S3OperationQueueOperationInformationalStatusDidChangeNotification;
extern NSString *S3OperationQueueOperationInformationalSubStatusDidChangeNotification;

/* Notification UserInfo Keys */
extern NSString *S3OperationObjectKey;
extern NSString *S3OperationObjectForRetryKey;