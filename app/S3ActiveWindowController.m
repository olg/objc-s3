//
//  S3ActiveWindowController.m
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ActiveWindowController.h"

#import "S3ConnectionInfo.h"
#import "S3ApplicationDelegate.h"
#import "S3Operation.h"
#import "S3OperationQueue.h"
#import "S3OperationLog.h"

@implementation S3ActiveWindowController

- (void)awakeFromNib
{
    _operations = [[NSMutableArray alloc] init];
}

#pragma mark -
#pragma mark S3OperationQueue Notifications

- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
{
    S3Operation *operation = [[notification userInfo] objectForKey:S3OperationObjectKey];
    unsigned index = [_operations indexOfObjectIdenticalTo:operation];
    if (index == NSNotFound) {
        return;
    }
    
    if ([operation state] == S3OperationCanceled || [operation state] == S3OperationDone || [operation state] == S3OperationCanceled) {
        [_operations removeObjectAtIndex:index];
        [[[NSApp delegate] operationLog] unlogOperation:operation];
    }
}

#pragma mark -

- (void)addToCurrentOperations:(S3Operation *)op
{
	if ([[[NSApp delegate] queue] addToCurrentOperations:op]) {
		[_operations addObject:op];
        [[[NSApp delegate] operationLog] logOperation:op];
    }
}

- (BOOL)hasActiveOperations
{
	return ([_operations count] > 0);
}

- (S3ConnectionInfo *)connectionInfo
{
    return _connectionInfo; 
}

- (void)setConnectionInfo:(S3ConnectionInfo *)aConnectionInfo
{
    [aConnectionInfo retain];
    [_connectionInfo release];
    _connectionInfo = aConnectionInfo;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc
{
	[self setConnectionInfo:nil];
    [_operations release];
	[super dealloc];
}

@end
