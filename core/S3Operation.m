//
//  S3Operation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/1/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Operation.h"

@implementation S3Operation

+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObjects:@"state", nil] triggerChangeNotificationsForDependentKey:@"active"];
}

- (id)init
{
	[super init];
	[self setState:S3OperationPending];
    [self setAllowsRetry:YES];
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

- (void)setStatus:(NSString *)status
{
    [_status release];
    _status = [status retain];
}

- (BOOL)active
{
    return ([self state] == S3OperationActive);
}

- (S3OperationState)state
{
    return _state;
}

- (void)setState:(S3OperationState)aState
{
    _state = aState;
    if (_state == S3OperationPending) {
        [self setStatus:@"Pending"];
    } else if (_state == S3OperationActive) {
        [self setStatus:@"Active"];
    } else if (_state == S3OperationError) {
        [self setStatus:@"Error"];
    } else if (_state == S3OperationCanceled) {
        [self setStatus:@"Canceled"];
    } else if (_state == S3OperationDone) {
        [self setStatus:@"Done"];
    }
}

- (BOOL)allowsRetry
{
    return _allowsRetry;
}

- (void)setAllowsRetry:(BOOL)yn
{
    _allowsRetry = yn;
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
    if ([self state] == S3OperationDone || [self state] == S3OperationCanceled || [self state] == S3OperationError) {
        return;
    }
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"This operation has been cancelled",NSLocalizedDescriptionKey,nil];
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-1 userInfo:d]];
	[self setState:S3OperationCanceled];
	[_delegate operationDidFail:self];
}

- (void)start:(id)sender;
{
	
}

@end
