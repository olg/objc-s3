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
#import "S3TransferRateCalculator.h"

@implementation S3ObjectDownloadOperation

- (NSData *)data
{
	return [NSData data];
}

- (id)initWithRequest:(NSURLRequest *)request toPath:(NSString *)path forSize:(long long)size
{
	[super init];
	_request = [request retain];
    _urlDownloadConnection = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	[_urlDownloadConnection setDestination:path allowOverwrite:NO];
    _rateCalculator = [[S3TransferRateCalculator alloc] init];
    [_rateCalculator setObjective:-1];
	return self;
}

- (void)dealloc
{
	[_request release];
	[_response release];
	[_urlDownloadConnection release];
	[super dealloc];
}

- (NSString *)kind
{
	return @"Object download";
}


- (void)setResponse:(NSHTTPURLResponse *)aResponse
{
	[aResponse retain];
    [_response release];
    _response = aResponse;
}

+ (S3ObjectDownloadOperation*)objectDownloadWithConnection:(S3Connection *)c bucket:(S3Bucket *)b object:(S3Object *)o toPath:(NSString *)path;
{
	NSURLRequest *rootConn = [c makeRequestForMethod:@"GET" withResource:[c resourceForBucket:b key:[o key]]];
	S3ObjectDownloadOperation *op = [[[S3ObjectDownloadOperation alloc] initWithRequest:rootConn toPath:path forSize:[o size]] autorelease];
	return op;
}

- (NSURLRequest *)download:(NSURLDownload *)download willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
{
    [self setStatus:@"Redirected"];
	if ([_delegate respondsToSelector:@selector(operationStateDidChange:)])
		[(id)_delegate operationStateDidChange:self];	
	return request;
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	[self setResponse:(NSHTTPURLResponse *)response];
    [self setStatus:@"Connected to server"];
    [_rateCalculator startTransferRateCalculator];
	if ([_delegate respondsToSelector:@selector(operationStateDidChange:)])
		[_delegate operationStateDidChange:self];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length 
{
    [_rateCalculator addBytesTransfered:length];
    [self setStatus:[NSString stringWithFormat:@"Receiving data %@%% (%@ %@/%@) %@",[_rateCalculator stringForObjectivePercentageCompleted], [_rateCalculator stringForCalculatedTransferRate], [_rateCalculator stringForShortDisplayUnit], [_rateCalculator stringForShortRateUnit], [_rateCalculator stringForEstimatedTimeRemaining]]];
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType
{
	return NO;
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    [_rateCalculator stopTransferRateCalculator];
	[self setState:S3OperationDone];
	[self retain];
	[_delegate operationDidFinish:self];
	[self release];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    [_rateCalculator stopTransferRateCalculator];
	[self setError:error];
	[self setState:S3OperationError];
	[_delegate operationDidFail:self];
}

- (void)stop:(id)sender
{
    if ([self active] == NO) {
        return;
    }
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"This operation has been cancelled",NSLocalizedDescriptionKey,nil];
	[_urlDownloadConnection cancel];
    [_rateCalculator stopTransferRateCalculator];
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-1 userInfo:d]];
	[self setState:S3OperationCanceled];
	[_delegate operationDidFail:self];
}

- (BOOL)operationSuccess
{
	int status = [_response statusCode];
	if (status==200)
		return TRUE;
	
	// Houston, we have a problem 
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	
	[dictionary setObject:[NSNumber numberWithInt:status] forKey:S3_ERROR_HTTP_STATUS_KEY];

	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:[_response statusCode] userInfo:dictionary]];
    [self setState:S3OperationError];
    return FALSE;
}

@end