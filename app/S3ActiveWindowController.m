//
//  S3ActiveWindowController.m
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "S3ActiveWindowController.h"

#import "S3Connection.h"
#import "S3Application.h"
#import "S3ListOperation.h"
#import "S3OperationQueue.h"

@implementation S3ActiveWindowController

-(void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo
{
}

-(void)operationStateChange:(S3Operation*)o;
{
    [[NSApp queue] operationStateChange:o];
}

-(void)operationDidFail:(S3Operation*)o
{
	[self willChangeValueForKey:@"hasActiveOperations"];
	[[NSApp queue] operationDidFail:o];
	[[self window] presentError:[o error] modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
	_operationCount--;
	[self didChangeValueForKey:@"hasActiveOperations"];
}

-(void)operationDidFinish:(S3Operation*)o
{
	[self willChangeValueForKey:@"hasActiveOperations"];
	[[NSApp queue] operationDidFinish:o];
	_operationCount--;
	[self didChangeValueForKey:@"hasActiveOperations"];
}

-(void)addToCurrentOperations:(S3Operation*)op
{
	[self willChangeValueForKey:@"hasActiveOperations"];
	if ([[NSApp queue] addToCurrentOperations:op])
		_operationCount++;
	[self didChangeValueForKey:@"hasActiveOperations"];
}

-(BOOL)hasActiveOperations
{
	return (_operationCount>0);
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

-(void)dealloc
{
	[self setConnection:nil];
	[super dealloc];
}

@end
