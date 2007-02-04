//
//  S3ActiveWindowController.m
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "S3ActiveWindowController.h"

#import "S3Connection.h"
#import "S3Extensions.h"
#import "S3Application.h"
#import "S3ListOperation.h"
#import "S3OperationQueue.h"

#define MAX_ACTIVE_OPERATIONS 4

@implementation S3ActiveWindowController

-(void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo
{
}

-(void)operationStateChange:(S3Operation*)o;
{
}

-(void)operationDidFail:(S3Operation*)o
{
	[self removeFromCurrentOperations:o];
	[[self window] presentError:[o error] modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
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
		[(S3OperationQueue*)[NSApp queue] unlogOperation:op];
	
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

-(void)addToCurrentOperations:(S3Operation*)op
{
	if (_currentOperations==nil)
		_currentOperations = [[NSMutableArray alloc] init];
	
	// Refresh operations should not be queued if another one is already in place
	if ([op isKindOfClass:[S3ListOperation class]])
		if ([_currentOperations containsObjectOfClass:[S3ListOperation class]])
			return;					
	
	[self willChangeValueForKey:@"currentOperations"];
	[_currentOperations addObject:op];
	[(S3OperationQueue*)[NSApp queue] logOperation:op];
	[self didChangeValueForKey:@"currentOperations"];
	
	if ([self canAcceptActiveOperations])
		[op start:self];
}

- (S3Connection *)connection
{
    return _connection; 
}
- (void)setConnection:(S3Connection *)aConnection
{
    [_connection release];
    _connection = [aConnection retain];
}

- (NSMutableArray *)currentOperations
{
    return _currentOperations; 
}
- (void)setCurrentOperations:(NSMutableArray *)aCurrentOperations
{
    [_currentOperations release];
    _currentOperations = [aCurrentOperations retain];
}

-(void)dealloc
{
	[self setConnection:nil];
	[self setCurrentOperations:nil];
	
	[super dealloc];
}

@end
