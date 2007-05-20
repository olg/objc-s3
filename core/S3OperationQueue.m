//
//  S3OperationQueue.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 04/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3OperationQueue.h"
#import "S3Operation.h"
#import "S3ListOperation.h"
#import "S3Extensions.h"

#define MAX_ACTIVE_OPERATIONS 4

/* Notifications */
NSString *S3OperationStateDidChangeNotification = @"S3OperationStateDidChangeNotification";
NSString *S3OperationDidFailNotification = @"S3OperationDidFailNotification";
NSString *S3OperationDidFinishNotification = @"S3OperationDidFinishNotification";

/* Notification UserInfo Keys */
NSString *S3OperationObjectKey = @"S3OperationObjectKey";
NSString *S3OperationObjectForRetryKey = @"S3OperationObjectForRetryKey";

@interface S3OperationQueue (PrivateAPI)
- (void)removeFromCurrentOperations:(S3Operation *)op;
- (void)startQualifiedOperations:(NSTimer *)timer;
- (void)rearmTimer;
- (void)disarmTimer;
@end

@implementation S3OperationQueue

- (id)init
{
	[super init];
	_operations = [[NSMutableArray alloc] init];
	_currentOperations = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
	[_operations release];
	[_currentOperations release];
	[self disarmTimer];
	[super dealloc];
}

#pragma mark -
#pragma mark Convenience Notification Registration

- (void)addQueueListener:(id)obj
{
    if ([obj respondsToSelector:@selector(s3OperationStateDidChange:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:obj selector:@selector(s3OperationStateDidChange:) name:S3OperationStateDidChangeNotification object:self];
    }
    if ([obj respondsToSelector:@selector(s3OperationDidFail:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:obj selector:@selector(s3OperationDidFail:) name:S3OperationDidFailNotification object:self];
    }
    if ([obj respondsToSelector:@selector(s3OperationDidFinish:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:obj selector:@selector(s3OperationDidFinish:) name:S3OperationDidFinishNotification object:self];
    }
}

- (void)removeQueueListener:(id)obj
{
    [[NSNotificationCenter defaultCenter] removeObserver:obj name:S3OperationStateDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:obj name:S3OperationDidFailNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:obj name:S3OperationDidFinishNotification object:self];
}

#pragma mark -
#pragma mark S3OperationDelegate Protocol Methods

- (void)operationStateDidChange:(S3Operation *)o;
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:o, S3OperationObjectKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:S3OperationStateDidChangeNotification object:self userInfo:dict];
}

- (void)operationDidFail:(S3Operation *)o
{
    // Retain object while it's in flux must be released at end!
    [o retain];
	[self removeFromCurrentOperations:o];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:o, S3OperationObjectKey, nil];
    // TODO: Figure out if the operation needs to be retried and send a new
    // retry operation object to be retried as S3OperationObjectForRetryKey.      
    // It appears valid retry on error codes: OperationAborted, InternalError
    if ([o state] == S3OperationError && [o allowsRetry] == YES) {
        NSDictionary *errorDict = [[o error] userInfo];
        NSString *errorCode = [errorDict objectForKey:S3_ERROR_CODE_KEY];
        if ([errorCode isEqualToString:@"InternalError"] == YES || [errorCode isEqualToString:@"OperationAborted"] || errorCode == nil) {
            // TODO: Create a retry operation from failed operation and add it to the operations to be performed.
            //S3Operation *retryOperation = nil;
            //[dict setObject:retryOperation forKey:S3OperationObjectForRetryKey];
            //[self addToCurrentOperations:retryOperation];            
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:S3OperationDidFailNotification object:self userInfo:dict];
    // Object is out of flux
    [o release];
}

- (void)operationDidFinish:(S3Operation *)o
{
	BOOL b = [o operationSuccess];
	if (!b) {
		[self operationDidFail:o];
		return;
	}
    // Retain object while it's in flux must be released at end!
    [o retain];
	[self removeFromCurrentOperations:o];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:o, S3OperationObjectKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:S3OperationDidFinishNotification object:self userInfo:dict];
    // Object out of flux
    [o release];
}

#pragma mark -
#pragma mark Key-value coding

- (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

- (NSMutableArray *)currentOperations
{
    return _currentOperations; 
}

- (NSMutableArray *)operations
{
    return _operations;
}

#pragma mark -
#pragma mark High-level operations

-(void)rearmTimer
{
	if (_timer==NULL)
		_timer = [[NSTimer scheduledTimerWithTimeInterval:0.20 target:self selector:@selector(startQualifiedOperations:) userInfo:nil repeats:NO] retain];
}

-(void)disarmTimer
{
	[_timer invalidate];
	[_timer release];
	_timer = NULL;	
}

- (void)logOperation:(id)op
{
    [self willChangeValueForKey:@"operations"];
	[_operations addObject:op];
    [self didChangeValueForKey:@"operations"];
}

- (void)unlogOperation:(id)op
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([[standardUserDefaults objectForKey:@"autoclean"] boolValue] == TRUE)
    {   
        [self willChangeValueForKey:@"operations"];
        [_operations removeObject:op];
        [self didChangeValueForKey:@"operations"];
    }
}

- (int)canAcceptPendingOperations
{
	int available = MAX_ACTIVE_OPERATIONS; // fallback
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber* maxOps = [standardUserDefaults objectForKey:@"maxoperations"];
	if (maxOps!=nil)
	{
		int value = [maxOps intValue]; 
		if ((value>0)&&(value<100)) // Let's be reasonable
			available = value;
	}
	
	NSEnumerator *e = [_currentOperations objectEnumerator];
	S3Operation *o;
	while (o = [e nextObject])
	{
		if ([o state]==S3OperationActive)
		{
			available--;
			if (available == 0)
				return available;
		}
	}
	return available;
}

- (void)removeFromCurrentOperations:(S3Operation *)op
{
    if ([op state]==S3OperationActive) {
        return;
    }
        
	[self willChangeValueForKey:@"currentOperations"];
	[_currentOperations removeObject:op];
	[self didChangeValueForKey:@"currentOperations"];
	
	if ([op state]==S3OperationDone) {
		[self unlogOperation:op];        
    }
    [self rearmTimer];
}

- (BOOL)addToCurrentOperations:(S3Operation *)op
{
	[self willChangeValueForKey:@"currentOperations"];
	[_currentOperations addObject:op];
	[self logOperation:op];
	[self didChangeValueForKey:@"currentOperations"];

	// Ensure this operation has the queue as its delegate.
	[op setDelegate:self];
    [self rearmTimer];
    return TRUE;
}

- (void)startQualifiedOperations:(NSTimer *)timer
{	
	int slotsAvailable = [self canAcceptPendingOperations];
	NSEnumerator *e = [_currentOperations objectEnumerator];
	S3Operation *o;
    // Pending retries get priority start status.
	while (o = [e nextObject]) {
		if (slotsAvailable == 0) {
			break;
		}
		if ([o state] == S3OperationPendingRetry) {
			[o start:self];
			slotsAvailable--;
		}
	}
    e = [_currentOperations objectEnumerator];
    while (o = [e nextObject]) {
		if (slotsAvailable == 0) {
			break;
		}
		if ([o state] == S3OperationPending) {
			[o start:self];
			slotsAvailable--;
		}
	}
	[self disarmTimer];
}

@end
