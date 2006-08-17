//
//  S3ObjectUploadOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/16/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ObjectUploadOperation.h"


@implementation S3ObjectUploadOperation

-(NSString*)kind
{
	return @"Object upload";
}

+(S3ObjectUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k data:(NSData*)n acl:(NSString*)acl
{
	NSMutableURLRequest* rootConn = [c makeRequestForMethod:@"PUT" withResource:[b name] subResource:k headers:[NSDictionary dictionaryWithObject:acl forKey:XAMZACL]];
	[rootConn setHTTPBody:n];
	S3ObjectUploadOperation* op = [[[S3ObjectUploadOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	return op;
}

@end

@implementation S3ObjectStreamedUploadOperation

-(id)initWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k path:(NSString*)path acl:(NSString*)acl
{
	[super initWithDelegate:d];
    
	NSNumber* n = [[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES] objectForKey:NSFileSize];
	_size = [n longLongValue];
	
	NSMutableDictionary* headers = [NSMutableDictionary dictionary];
	[headers setObject:acl forKey:XAMZACL];
	[headers setObject:[n stringValue] forKey:@"Content-Length"];
	[headers setObject:@"CFNetwork" forKey:@"User-Agent"];
	[headers setObject:@"*/*" forKey:@"Accept"];
	[headers setObject:DEFAULT_HOST forKey:@"Host"];

	
	obuffer = [[NSMutableData alloc] init];//
	_headerData = [c createHeaderDataForMethod:@"PUT" withResource:[b name] subResource:k headers:headers];
		
	NSHost *host = [NSHost hostWithName:DEFAULT_HOST];
	// iStream and oStream are instance variables
	[NSStream getStreamsToHost:host port:80 inputStream:&istream outputStream:&ostream];
	fstream = [NSInputStream inputStreamWithFileAtPath:path];
    [istream retain];
	[ostream retain];
	[fstream retain];
	
	[istream setDelegate:self];
	[ostream setDelegate:self];
	[fstream setDelegate:self];
	[istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[fstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[istream open];
    [ostream open];
    [fstream open];

	return self;
}

+(S3ObjectStreamedUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k path:(NSString*)p acl:(NSString*)a
{
	return [[[S3ObjectStreamedUploadOperation alloc] initWithConnection:c delegate:d bucket:b key:k path:p acl:a] autorelease];;
}

-(NSData*)data
{
	if (_response == NULL)
		return [NSData data];
	else
		return [(NSData*)CFHTTPMessageCopyBody(_response) autorelease];
}

- (void)invalidate 
{
	[istream close];
	[ostream close];
	[fstream close];
	[istream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[ostream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[fstream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[fstream release];
	[istream release];
	[ostream release];
	istream = nil;
	ostream = nil;
	fstream = nil;
	[ibuffer release];
	[obuffer release];
	ibuffer = nil;
	obuffer = nil;
}

-(NSString*)kind
{
	return @"Object upload";
}

-(void)stop:(id)sender
{	
	NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:@"Cancel",NSLocalizedDescriptionKey,
		@"This operation has been cancelled",NSLocalizedDescriptionKey,nil];
	[self invalidate];
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-1 userInfo:d]];
	[self setStatus:@"Cancelled"];
	[self setActive:NO];
	[_delegate operationDidFail:self];
}

-(BOOL)operationSuccess
{
	int status = CFHTTPMessageGetResponseStatusCode(_response);
	if (status/100==2)
		return TRUE;
	
	// Houston, we have a problem 
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSArray* a;
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:[self data] options:NSXMLDocumentTidyXML error:&_error] autorelease];
	
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
				
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:status userInfo:dictionary]];
	return FALSE;
}

-(void)dealloc
{
	[istream release];
	[ostream release];
	[fstream release];
	CFRelease(_headerData);	
	[super dealloc];
}


- (void)connectionDidFinishLoading {
    [self setStatus:@"Done"];
	[self setActive:NO];
	[_delegate operationDidFinish:self];
}


- (void)connectionDidFailWithError:(NSError *)error {
	[self setError:error];
    [self setStatus:@"Error"];
	[self setActive:NO];
	[_delegate operationDidFail:self];
}

#define FILEBUFFERSIZE 16

- (void)processFileBytes 
{
	if (![fstream hasBytesAvailable])
		[fstream close];
	if ([obuffer length]==0)
	{
		[obuffer setLength:FILEBUFFERSIZE*1024];
		int read = [fstream read:[obuffer mutableBytes] maxLength:[obuffer length]];
		[obuffer setLength:read];
		if (read==0)
			[fstream close];

	}
	//NSLog(@"F-> %d",[fstream streamStatus]);
}
	
- (void)processOutgoingBytes {
	
    if (![ostream hasSpaceAvailable]) {
        return;
    }
	
	if (_headerData!=NULL) 
	{
		int w = [ostream write:CFDataGetBytePtr(_headerData) maxLength:CFDataGetLength(_headerData)];
		if (w < CFDataGetLength(_headerData))
			NSLog(@"Header data was not sent in just one write. Oops");
		CFRelease(_headerData);
		_headerData = NULL;
	}
	
    unsigned olen = [obuffer length];
    if (0 < olen) {
        int writ = [ostream write:[obuffer bytes] maxLength:olen];
        // buffer any unwritten bytes for later writing
        if (writ < olen) {
            memmove([obuffer mutableBytes], [obuffer mutableBytes] + writ, olen - writ);
            [obuffer setLength:olen - writ];
            return;
        }
        [obuffer setLength:0];
		_sent = _sent + writ;
		int percent = _sent * 100.0 / _size;
		[self setStatus:[NSString stringWithFormat:@"Sending data %d %%",percent]];
    }
	[self processFileBytes];
	
	
	if (0 == [obuffer length]) 
	{
		if (([fstream streamStatus]==NSStreamStatusAtEnd)||([fstream streamStatus]==NSStreamStatusClosed)||([fstream streamStatus]==NSStreamStatusError))
		{
			[ostream close];
		}
	}		
	//NSLog(@"O-> %d",[ostream streamStatus]);
}

- (BOOL)analyzeIncomingBytes {
    CFHTTPMessageRef working = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    CFHTTPMessageAppendBytes(working, [ibuffer bytes], [ibuffer length]);
    
	_response = working;
	CFRetain(_response);
			 
    CFRelease(working);
    return YES;
}

- (void)processIncomingBytes
{        
	if(!ibuffer) {
		ibuffer = [[NSMutableData data] retain];
	}
	uint8_t buf[1024];
	int len = 0;
	len = [istream read:buf maxLength:1024];
	if(len>0) {
		[ibuffer appendBytes:(const void *)buf length:len];
	} else {
		[istream close];
	}
	if ([self analyzeIncomingBytes])
	{
		[istream close];
		[self invalidate];
		if ([self operationSuccess])
			[self connectionDidFinishLoading];
		else
			[self connectionDidFailWithError:[self error]];
	}
	
	//NSLog(@"I-> %d",[istream streamStatus]);
}	

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode 
{
#if 0
	if (stream==fstream)
		NSLog(@"fstream %d %d",eventCode,[stream streamStatus]);
	if (stream==ostream)
		NSLog(@"ostream %d %d",eventCode,[stream streamStatus]);
	if (stream==istream)
		NSLog(@"istream %d %d",eventCode,[stream streamStatus]);
    switch(eventCode) {
		case NSStreamEventNone:
			NSLog(@"    NSStreamEventNone");
			break;
		case NSStreamEventOpenCompleted:
			NSLog(@"    NSStreamEventOpenCompleted");
			break;
		case NSStreamEventHasBytesAvailable:
			NSLog(@"    NSStreamEventHasBytesAvailable");
			break;
		case NSStreamEventHasSpaceAvailable:
			NSLog(@"    NSStreamEventHasSpaceAvailable");
			break;
		case NSStreamEventErrorOccurred:
			NSLog(@"    NSStreamEventErrorOccurred %@",[stream streamError]);
			break;
		case NSStreamEventEndEncountered:
			NSLog(@"    NSStreamEventEndEncountered");
			break;
	}
#endif
	
    switch(eventCode) {
		case NSStreamEventOpenCompleted:
			if (stream == ostream)
				[self setStatus:@"Connected to server"];
			break;
        case NSStreamEventHasSpaceAvailable:
			if (stream == ostream)
				[self processOutgoingBytes];
            break;
        case NSStreamEventHasBytesAvailable:
			if (stream == istream)
				[self processIncomingBytes];
			else if (stream == fstream)
				[self processFileBytes];
				break;
		case NSStreamEventEndEncountered:
			if (stream == istream)
				[self analyzeIncomingBytes];
		default:
			break;
	}
}


@end
