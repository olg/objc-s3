//
//  S3NSURLConnectionOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3NSURLConnectionOperation.h"


@implementation S3NSURLConnectionOperation

- (id)initWithRequest:(NSURLRequest*)request
{
	[super init];
	_request = [request retain];
	_data = [[NSMutableData alloc] init];
	return self;
}

- (void)start:(id)sender
{
	_urlConnection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
	[self setState:S3OperationActive];
}

- (void)dealloc
{
	[_request release];
	[_response release];
	[_urlConnection release];
	[_data release];
	[super dealloc];
}

- (void)setResponse:(NSHTTPURLResponse *)aResponse
{
    [_response release];
    _response = [aResponse retain];
}

- (BOOL)operationSuccess
{
	int status = [_response statusCode];
	if (status == 200 || status == 204)
		return TRUE;
	
	// Houston, we have a problem 
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	NSArray *a;
	NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLNodeOptionsNone error:&_error] autorelease];
	
	a = [[d rootElement] nodesForXPath:@"//Code" error:&_error];
    if ([a count]==1) {
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:NSLocalizedDescriptionKey];            
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:S3_ERROR_CODE_KEY];
    }
    a = [[d rootElement] nodesForXPath:@"//Message" error:&_error];
    if ([a count]==1)
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:NSLocalizedRecoverySuggestionErrorKey];
    a = [[d rootElement] nodesForXPath:@"//Resource" error:&_error];
    if ([a count]==1)
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:S3_ERROR_RESOURCE_KEY];

    [dictionary setObject:[NSNumber numberWithInt:status] forKey:S3_ERROR_HTTP_STATUS_KEY];
        
    [self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:[_response statusCode] userInfo:dictionary]];
    [self setState:S3OperationError];
    return FALSE;
}

- (void)stop:(id)sender
{	
	[_urlConnection cancel];
	[super stop:sender];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    [self setStatus:@"Redirected"];
	if ([_delegate respondsToSelector:@selector(operationStateDidChange:)])
		[(id)_delegate operationStateDidChange:self];	
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self setResponse:(NSHTTPURLResponse*)response];
	[self willChangeValueForKey:@"data"];
    [_data setLength:0];
	[self didChangeValueForKey:@"data"];
    [self setStatus:@"Connected to server"];
	if ([_delegate respondsToSelector:@selector(operationStateDidChange:)])
		[_delegate operationStateDidChange:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self willChangeValueForKey:@"data"];
    [_data appendData:data];
	[self didChangeValueForKey:@"data"];
    [self setStatus:@"Receiving data"];
	if ([_delegate respondsToSelector:@selector(operationStateDidChange:)])
		[_delegate operationStateDidChange:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if ([self operationSuccess] == NO) {
		[self connection:connection didFailWithError:[self error]];
		return;
	}
	[self setState:S3OperationDone];
	[_delegate operationDidFinish:self];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self setError:error];
	[self setState:S3OperationError];
	[_delegate operationDidFail:self];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil; // Don't cache
}

@end
