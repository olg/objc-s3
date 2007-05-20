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

- (NSData*)data
{
	return _data;
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
    [self setError:[self errorFromStatus:status data:[self data]]];
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
