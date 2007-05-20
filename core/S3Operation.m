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

// Convenience method which setup an NSError from HTTP status and data by checking S3 error XML Documents
-(NSError*)errorFromStatus:(int)status data:(NSData*)data
{
    NSError* error = nil;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:[NSNumber numberWithInt:status] forKey:S3_ERROR_HTTP_STATUS_KEY];
    
    NSArray *a;
    NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error] autorelease];
    if (error!=NULL)
        [dictionary setObject:error forKey:NSUnderlyingErrorKey];
    
    a = [[d rootElement] nodesForXPath:@"//Code" error:&error];
    if ([a count]==1) {
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:NSLocalizedDescriptionKey];
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:S3_ERROR_CODE_KEY];
    }
        
    a = [[d rootElement] nodesForXPath:@"//Message" error:&error];
    if (error!=NULL)
        [dictionary setObject:error forKey:NSUnderlyingErrorKey];
    if ([a count]==1)
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:NSLocalizedRecoverySuggestionErrorKey];
    
    a = [[d rootElement] nodesForXPath:@"//Resource" error:&error];
    if (error!=NULL)
        [dictionary setObject:error forKey:NSUnderlyingErrorKey];
    if ([a count]==1)
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:S3_ERROR_RESOURCE_KEY];
    
    return [NSError errorWithDomain:S3_ERROR_DOMAIN code:status userInfo:dictionary];
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
