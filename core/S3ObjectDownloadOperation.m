//
//  S3ObjectDownloadOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ObjectDownloadOperation.h"

#import "S3Connection.h"
#import "S3Object.h"

#ifndef S3_DOWNLOADS_NSURLCONNECTION

@implementation S3ObjectDownloadOperation

-(NSData*)data
{
	return [NSData data];
}

-(id)initWithRequest:(NSURLRequest*)request delegate:(id)delegate toPath:(NSString*)path forSize:(long long)size
{
	[super initWithDelegate:delegate];
	_request = [request retain];
    _connection = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	_size = size;
	_percent = 0;
	[_connection setDestination:path allowOverwrite:NO];
	return self;
}

-(void)dealloc
{
	[_request release];
	[_response release];
	[_connection release];
	[super dealloc];
}

-(NSString*)kind
{
	return @"Object download";
}

+(S3ObjectDownloadOperation*)objectDownloadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b object:(S3Object*)o toPath:(NSString*)path;
{
	NSURLRequest* rootConn = [c makeRequestForMethod:@"GET" withResource:[b name] subResource:[o key]];
	S3ObjectDownloadOperation* op = [[[S3ObjectDownloadOperation alloc] initWithRequest:rootConn delegate:d toPath:path forSize:[o size]] autorelease];
	return op;
}

- (NSURLRequest *)download:(NSURLDownload *)download willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
{
    [self setStatus:@"Redirected"];
	if ([_delegate respondsToSelector:@selector(operationStateChange:)])
		[(id)_delegate operationStateChange:self];	
	return request;
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    [_response release];
    _response = [response retain];
    [self setStatus:@"Connected to server"];
	if ([_delegate respondsToSelector:@selector(operationStateChange:)])
		[_delegate operationStateChange:self];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length 
{
	if (_size!=-1)
	{
		_received = _received + length;
		int percent = _received * 100.0 / _size;
		if (_percent != percent) 
		{
			[self setStatus:[NSString stringWithFormat:@"Receiving data %d %%",percent]];
			_percent = percent;
		}
	}	
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType
{
	return NO;
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    [self setStatus:@"Done"];
	[self setActive:NO];
	[_delegate operationDidFinish:self];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
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

-(BOOL)operationSuccess
{
	int status = [_response statusCode];
	if (status/100==2)
		return TRUE;
	
	// Houston, we have a problem 
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	
	[dictionary setObject:[NSNumber numberWithInt:status] forKey:S3_ERROR_HTTP_STATUS_KEY];
	
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:[_response statusCode] userInfo:dictionary]];
	return FALSE;
}

@end

#else

@implementation S3ObjectDownloadOperation

-(void)dealloc
{
	[_object release];
	[super dealloc];
}

-(NSString*)kind
{
	return @"Object download";
}

+(S3ObjectDownloadOperation*)objectDownloadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b object:(S3Object*)o;
{
	NSURLRequest* rootConn = [c makeRequestForMethod:@"GET" withResource:[b name] subResource:[o key]];
	S3ObjectDownloadOperation* op = [[[S3ObjectDownloadOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	[op setObject:o];
	return op;
}

-(NSData*)data
{
	return _data;
}

- (S3Object *)object
{
    return _object; 
}

- (void)setObject:(S3Object *)anObject
{
    [_object release];
    _object = [anObject retain];
}

@end

#endif



