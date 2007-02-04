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


@interface S3Operation (RefreshComparator)

-(BOOL)isRefreshOperationWithDelegate:(id)o;

@end

@implementation S3Operation (RefreshComparator)

-(BOOL)isRefreshOperationWithDelegate:(id)o
{
    if ([self isKindOfClass:[S3ListOperation class]])
		if ([self delegate]==o)
            return TRUE;
    return FALSE;
}

@end


@implementation S3OperationQueue

-(id)init
{
	[super init];
	_operations = [[NSMutableArray alloc] init];
	return self;
}

-(void)dealloc
{
	[_operations release];
	[_currentOperations release];
    
	[super dealloc];
}

-(void)operationStateChange:(S3Operation*)o;
{
}

-(void)operationDidFail:(S3Operation*)o
{
	[self removeFromCurrentOperations:o];
}

-(void)operationDidFinish:(S3Operation*)o
{
	BOOL b = [o operationSuccess];
	if (!b) {
		[self operationDidFail:o];
		return;
	}
	[self removeFromCurrentOperations:o];
}

#pragma mark -
#pragma mark Key-value coding

- (NSMutableArray *)currentOperations
{
    return _currentOperations; 
}

- (unsigned int)countOfOperations 
{
    return [_operations count];
}

- (id)objectInOperationsAtIndex:(unsigned int)index 
{
    return [_operations objectAtIndex:index];
}

- (void)insertObject:(id)anObject inOperationsAtIndex:(unsigned int)index 
{
    [_operations insertObject:anObject atIndex:index];
}

- (void)removeObjectFromOperationsAtIndex:(unsigned int)index 
{
    [_operations removeObjectAtIndex:index];
}

- (void)replaceObjectInOperationsAtIndex:(unsigned int)index withObject:(id)anObject 
{
    [_operations replaceObjectAtIndex:index withObject:anObject];
}

#pragma mark -
#pragma mark High-level operations

-(void)logOperation:(id)op
{
	[self insertObject:op inOperationsAtIndex:[self countOfOperations]];
}

-(void)unlogOperation:(id)op
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([[standardUserDefaults objectForKey:@"autoclean"] boolValue] == TRUE)
    {   
        unsigned i = [_operations indexOfObject:op];
        if (i != NSNotFound) {
            [[op retain] autorelease];
            [self removeObjectFromOperationsAtIndex:i];			
        }
    }
}

-(int)canAcceptActiveOperations
{
	int active = MAX_ACTIVE_OPERATIONS;
	NSEnumerator* e = [_currentOperations objectEnumerator];
	S3Operation* o;
	while (o = [e nextObject])
	{
		if ([o state]==S3OperationActive)
		{
			active--;
			if (active==0)
				return FALSE;
		}
	}
	return TRUE;
}

-(void)removeFromCurrentOperations:(S3Operation*)op
{
	[self willChangeValueForKey:@"currentOperations"];
	[_currentOperations removeObject:op];
	[self didChangeValueForKey:@"currentOperations"];
	
	if ([op state]==S3OperationDone)
		[self unlogOperation:op];
	
	if (![self canAcceptActiveOperations])
		return;
	
	NSEnumerator* e = [_currentOperations objectEnumerator];
	S3Operation* o;
	while (o = [e nextObject])
	{
		if ([o state]==S3OperationPending)
		{
			[o start:self];
			return;
		}
	}
}

-(BOOL)addToCurrentOperations:(S3Operation*)op
{
	if (_currentOperations==nil)
		_currentOperations = [[NSMutableArray alloc] init];
	
	// Refresh operations should not be queued if another one is already in place
	if ([op isKindOfClass:[S3ListOperation class]])
		if ([_currentOperations hasObjectSatisfying:@selector(isRefreshOperationWithDelegate:) withArgument:[op delegate]])
            return FALSE;					
    
	[self willChangeValueForKey:@"currentOperations"];
	[_currentOperations addObject:op];
	[self logOperation:op];
	[self didChangeValueForKey:@"currentOperations"];
	
	if ([self canAcceptActiveOperations])
		[op start:self];
    
    return TRUE;
}

@end
