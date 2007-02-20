//
//  S3Operation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/1/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Operation.h"

@implementation S3Operation

- (id)initWithDelegate:(id)delegate
{
	[super init];
	_delegate = delegate;
	_status = @"Pending";
	[self setState:S3OperationPending];
	[self setActive:NO];
	return self;
}

- (void)dealloc
{
	[_status release];
	[_error release];
	[super dealloc];
}

- (id)delegate
{
	return _delegate; 
}

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

- (NSString *)status
{
    return _status; 
}

- (void)setStatus:(NSString *)aStatus
{
    [_status release];
    _status = [aStatus retain];
}

- (BOOL)active
{
    return _active;
}
- (void)setActive:(BOOL)flag
{
    _active = flag;
}

- (S3OperationState)state
{
    return _state;
}
- (void)setState:(S3OperationState)aState
{
    _state = aState;
}

- (NSError *)error
{
    return _error; 
}
- (void)setError:(NSError *)anError
{
    [_error release];
    _error = [anError retain];
}

-(BOOL)operationSuccess
{
	return FALSE;
}

-(void)stop:(id)sender
{	
	NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:@"Cancel",NSLocalizedDescriptionKey,
		@"This operation has been cancelled",NSLocalizedDescriptionKey,nil];
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-1 userInfo:d]];
	[self setStatus:@"Cancelled"];
	[self setActive:NO];
	[self setState:S3OperationError];
	[_delegate operationDidFail:self];
}

- (void)start:(id)sender;
{
	
}

@end
