//
//  S3Operation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/1/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Operation.h"


@implementation S3Operation

-(id)initWithRequest:(NSURLRequest*)request delegate:(id)delegate
{
	[super init];
	[self setActive:YES];
	_request = [request retain];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	_delegate = delegate;
	_data = [[NSMutableData alloc] init];
	_status = @"Active";
	return self;
}

-(void)dealloc
{
	[_connection release];
	[_request release];
	[_response release];
	[_data release];
	[_status release];
	[_error release];
	[super dealloc];
}


-(BOOL)operationSuccess
{
	int status = [_response statusCode];
	if (status/100==2)
		return TRUE;
	
	// Houston, we have a problem 
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSArray* a;
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLDocumentTidyXML error:&_error] autorelease];
	
	a = [[d rootElement] nodesForXPath:@"//Code" error:&_error];
	if ([a count]==1)
		[dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:NSLocalizedDescriptionKey];
	a = [[d rootElement] nodesForXPath:@"//Message" error:&_error];
	if ([a count]==1)
		[dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:NSLocalizedRecoverySuggestionErrorKey];
	a = [[d rootElement] nodesForXPath:@"//Resource" error:&_error];
	if ([a count]==1)
		[dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:S3_ERROR_RESOURCE_KEY];
	
	[dictionary setObject:[NSNumber numberWithInt:status] forKey:S3_ERROR_HTTP_STATUS_KEY];
	
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:[_response statusCode] userInfo:dictionary]];
	return FALSE;
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


- (NSError *)error
{
    return _error; 
}
- (void)setError:(NSError *)anError
{
    [_error release];
    _error = [anError retain];
}


- (NSHTTPURLResponse *)response
{
    return _response; 
}

- (void)setResponse:(NSHTTPURLResponse *)aResponse
{
    [_response release];
    _response = [aResponse retain];
}


-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    [self setStatus:@"Redirected"];
	if ([_delegate respondsToSelector:@selector(operationStateChange:)])
		[(id)_delegate operationStateChange:self];	
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self setResponse:(NSHTTPURLResponse*)response];
	[self willChangeValueForKey:@"data"];
    [_data setLength:0];
	[self didChangeValueForKey:@"data"];
    [self setStatus:@"Connected to server"];
	if ([_delegate respondsToSelector:@selector(operationStateChange:)])
		[_delegate operationStateChange:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self willChangeValueForKey:@"data"];
    [_data appendData:data];
	[self didChangeValueForKey:@"data"];
    [self setStatus:@"Receiving data"];
	if ([_delegate respondsToSelector:@selector(operationStateChange:)])
		[_delegate operationStateChange:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self setStatus:@"Done"];
	[self setActive:NO];
	[_delegate operationDidFinish:self];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self setError:error];
    [self setStatus:@"Error"];
	[self setActive:NO];
	[_delegate operationDidFail:self];
}

-(void)stop:(id)sender
{	
	NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:@"Cancel",NSLocalizedDescriptionKey,
		@"This operation has been cancelled",NSLocalizedDescriptionKey,nil];
	[_connection cancel];
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-1 userInfo:d]];
	[self setStatus:@"Cancelled"];
	[self setActive:NO];
	[_delegate operationDidFail:self];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil; // Don't cache
}


@end
