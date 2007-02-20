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

- (void)awakeFromNib
{
    _operations = [[NSMutableArray alloc] init];
}

-(void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo
{
}

#pragma mark -
#pragma mark S3OperationQueue Notifications

-(void)s3OperationStateDidChange:(NSNotification *)notification
{
}

-(void)s3OperationDidFail:(NSNotification *)notification
{
    S3Operation *o = [[notification userInfo] objectForKey:S3OperationObjectKey];
    unsigned index = [_operations indexOfObjectIdenticalTo:o];
    if (index == NSNotFound) {
        return;
    }

	[self willChangeValueForKey:@"hasActiveOperations"];
	[[self window] presentError:[o error] modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
	[_operations removeObjectAtIndex:index];
	[self didChangeValueForKey:@"hasActiveOperations"];
}

-(void)s3OperationDidFinish:(NSNotification *)notification
{
    S3Operation *operation = [[notification userInfo] objectForKey:S3OperationObjectKey];
    unsigned index = [_operations indexOfObjectIdenticalTo:operation];
    if (index == NSNotFound) {
        return;
    }
    
	[self willChangeValueForKey:@"hasActiveOperations"];
	[_operations removeObjectAtIndex:index];
	[self didChangeValueForKey:@"hasActiveOperations"];
}

#pragma mark -

-(void)addToCurrentOperations:(S3Operation*)op
{
	[self willChangeValueForKey:@"hasActiveOperations"];
	if ([[NSApp queue] addToCurrentOperations:op])
		[_operations addObject:op];
	[self didChangeValueForKey:@"hasActiveOperations"];
}

-(BOOL)hasActiveOperations
{
	return ([_operations count] > 0);
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

#pragma mark -
#pragma mark Dealloc

-(void)dealloc
{
	[self setConnection:nil];
    [_operations release];
	[super dealloc];
}

@end
