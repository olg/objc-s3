//
//  S3OperationQueue.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 04/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3OperationQueue.h"
#import "S3Extensions.h"

#define MAX_ACTIVE_OPERATIONS 4

/* Notifications */
NSString *S3OperationQueueOperationStateDidChangeNotification = @"S3OperationQueueOperationStateDidChangeNotification";
NSString *S3OperationQueueOperationInformationalStatusDidChangeNotification = @"S3OperationQueueOperationInformationalStatusDidChangeNotification";
NSString *S3OperationQueueOperationInformationalSubStatusDidChangeNotification = @"S3OperationQueueOperationInformationalSubStatusDidChangeNotification";

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

- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    
    if (self != nil) {
        _delegate = delegate;
        _currentOperations = [[NSMutableArray alloc] init];
        _activeOperations = [[NSMutableArray alloc] init];        
    }
    
    return self;
}

- (id)init
{
    return [self initWithDelegate:nil];
}

- (void)dealloc
{
	[_currentOperations release];
    [_activeOperations release];
	[self disarmTimer];
	[super dealloc];
}

#pragma mark -
#pragma mark Convenience Notification Registration

- (void)addQueueListener:(id)obj
{
    SEL operationQueueOperationStateDidChangeSelector = @selector(operationQueueOperationStateDidChange:);
    if ([obj respondsToSelector:operationQueueOperationStateDidChangeSelector]) {
        [[NSNotificationCenter defaultCenter] addObserver:obj selector:operationQueueOperationStateDidChangeSelector name:S3OperationQueueOperationStateDidChangeNotification object:self];
    }
    SEL operationQueueOperationInformationalStatusDidChangeSelector = @selector(operationQueueOperationInformationalStatusDidChange:);
    if ([obj respondsToSelector:operationQueueOperationInformationalStatusDidChangeSelector]) {
        [[NSNotificationCenter defaultCenter] addObserver:obj selector:operationQueueOperationInformationalStatusDidChangeSelector name:S3OperationQueueOperationInformationalStatusDidChangeNotification object:self];
    }
    SEL operationQueueOperationInformationalSubStatusDidChangeSelector = @selector(operationQueueOperationInformationalSubStatusDidChange:);
    if ([obj respondsToSelector:operationQueueOperationInformationalSubStatusDidChangeSelector]) {
        [[NSNotificationCenter defaultCenter] addObserver:obj selector:operationQueueOperationInformationalSubStatusDidChangeSelector name:S3OperationQueueOperationInformationalSubStatusDidChangeNotification object:self];
    }
}

- (void)removeQueueListener:(id)obj
{
    [[NSNotificationCenter defaultCenter] removeObserver:obj name:S3OperationQueueOperationStateDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:obj name:S3OperationQueueOperationInformationalStatusDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:obj name:S3OperationQueueOperationInformationalSubStatusDidChangeNotification object:self];
}

#pragma mark -
#pragma mark S3OperationDelegate Protocol Methods

- (void)operationStateDidChange:(S3Operation *)o;
{
    if ([o state] >= S3OperationCanceled) {
        // Retain object while it's in flux must be released at end!
        [o retain];
        [self removeFromCurrentOperations:o];
        
        if ([o state] == S3OperationError) {
            // TODO: Figure out if the operation needs to be retried and send a new
            // retry operation object to be retried as S3OperationObjectForRetryKey.      
            // It appears valid retry on error codes: OperationAborted, InternalError        
            //    if ([o state] == S3OperationError && [o allowsRetry] == YES) {
            //        NSDictionary *errorDict = [[o error] userInfo];
            //        NSString *errorCode = [errorDict objectForKey:S3_ERROR_CODE_KEY];
            //        if ([errorCode isEqualToString:@"InternalError"] == YES || [errorCode isEqualToString:@"OperationAborted"] || errorCode == nil) {
            //            // TODO: Create a retry operation from failed operation and add it to the operations to be performed.
            //            //S3Operation *retryOperation = nil;
            //            //[dict setObject:retryOperation forKey:S3OperationObjectForRetryKey];
            //            //[self addToCurrentOperations:retryOperation];            
            //        }
            //    }
        }
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:o, S3OperationObjectKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:S3OperationQueueOperationStateDidChangeNotification object:self userInfo:dict];
    
    if ([o state] >= S3OperationCanceled) {
        // Object is out of flux
        [o release];
    }
}

- (void)operationInformationalStatusDidChange:(S3Operation *)o
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:o, S3OperationObjectKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:S3OperationQueueOperationInformationalStatusDidChangeNotification object:self userInfo:dict];
}

- (void)operationInformationalSubStatusDidChange:(S3Operation *)o
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:o, S3OperationObjectKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:S3OperationQueueOperationInformationalSubStatusDidChangeNotification object:self userInfo:dict];
}

- (NSUInteger)operationQueuePosition:(S3Operation *)o
{
    NSUInteger position = [_activeOperations indexOfObject:o];
    return position;
}

#pragma mark -
#pragma mark Key-value coding

- (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

- (NSArray *)currentOperations
{
    return [NSArray arrayWithArray:_currentOperations];
}

#pragma mark -
#pragma mark High-level operations

-(void)rearmTimer
{
	if (_timer==NULL) {
		_timer = [[NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(startQualifiedOperations:) userInfo:nil repeats:YES] retain];
    }
}

-(void)disarmTimer
{
	[_timer invalidate];
	[_timer release];
	_timer = NULL;	
}

- (int)canAcceptPendingOperations
{
	int available = MAX_ACTIVE_OPERATIONS; // fallback
    if (_delegate && [_delegate respondsToSelector:@selector(maximumNumberOfSimultaneousOperationsForOperationQueue:)]) {
        int maxNumber = [_delegate maximumNumberOfSimultaneousOperationsForOperationQueue:self];
        if ((maxNumber > 0) && (maxNumber < 100)) { // Let's be reasonable
            available = maxNumber;
        }
    }
	
	S3Operation *o;
	for (o in _currentOperations)
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
    if ([op state] == S3OperationActive) {
        return;
    }
        
	[self willChangeValueForKey:@"currentOperations"];
	[_currentOperations removeObject:op];
	[self didChangeValueForKey:@"currentOperations"];
	
    NSUInteger objectIndex = [_activeOperations indexOfObject:op];
    if (objectIndex != NSNotFound) {
        [_activeOperations replaceObjectAtIndex:objectIndex withObject:[NSNull null]];
    }
    
    [self rearmTimer];
}

- (BOOL)addToCurrentOperations:(S3Operation *)op
{
	[self willChangeValueForKey:@"currentOperations"];
	[_currentOperations addObject:op];
	[self didChangeValueForKey:@"currentOperations"];

	// Ensure this operation has the queue as its delegate.
	[op setDelegate:self];
    [self rearmTimer];
    return TRUE;
}

- (void)startQualifiedOperations:(NSTimer *)timer
{
	int slotsAvailable = [self canAcceptPendingOperations];
	S3Operation *o;

    if (slotsAvailable == 0) {
        [self disarmTimer];
        return;
    }
    
    // Pending retries get priority start status.
	for (o in _currentOperations) {
        if (slotsAvailable == 0) {
            break;
        }
        
		if ([o state] == S3OperationPendingRetry) {
            
            NSUInteger objectIndex = [_activeOperations indexOfObject:[NSNull null]];
            if (objectIndex == NSNotFound) {
                [_activeOperations addObject:o];
            } else {
                [_activeOperations replaceObjectAtIndex:objectIndex withObject:o];                
            }
            
			[o start:self];
            slotsAvailable--;
		}
	}
    for (o in _currentOperations) {
        if (slotsAvailable == 0) {
            break;
        }
        
		if ([o state] == S3OperationPending) {

            NSUInteger objectIndex = [_activeOperations indexOfObject:[NSNull null]];
            if (objectIndex == NSNotFound) {
                [_activeOperations addObject:o];
            } else {
                [_activeOperations replaceObjectAtIndex:objectIndex withObject:o];                
            }
			[o start:self];
            slotsAvailable--;
		}
	}
    [self disarmTimer];
}

@end
