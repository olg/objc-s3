//
//  S3ObjectUploadOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/16/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ObjectUploadOperation.h"

#define UPLOAD_HTTP_METHOD @"PUT"

@implementation S3ObjectUploadOperation

-(NSString*)kind
{
	return @"Object upload";
}

+(S3ObjectUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k data:(NSData*)n acl:(NSString*)acl mimeType:(NSString*)mimeType
{
	NSDictionary* headers;
	if ((mimeType==nil) || ([[mimeType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]))
		headers = [NSDictionary dictionaryWithObject:acl forKey:XAMZACL];
	else
		headers = [NSDictionary dictionaryWithObjectsAndKeys:acl,XAMZACL,mimeType,@"Content-Type",nil];
		
	NSMutableURLRequest* rootConn = [c makeRequestForMethod:UPLOAD_HTTP_METHOD withResource:[b name] subResource:k headers:headers];
	[rootConn setHTTPBody:n];
	S3ObjectUploadOperation* op = [[[S3ObjectUploadOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	return op;
}

@end


@implementation S3ObjectStreamedUploadOperation

-(id)initWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k path:(NSString*)path acl:(NSString*)acl mimeType:(NSString*)mimeType
{
	[super initWithDelegate:d];
    
	NSNumber* n = [[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES] objectForKey:NSFileSize];
	_size = [n longLongValue];
	_path = [path retain];
	
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    [headers setObject:acl forKey:XAMZACL];
	[headers setObject:[n stringValue] forKey:@"Content-Length"];
	[headers setObject:@"CFNetwork" forKey:@"User-Agent"];
	[headers setObject:@"*/*" forKey:@"Accept"];
	[headers setObject:DEFAULT_HOST forKey:@"Host"];
	if ((mimeType!=nil) && (![[mimeType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]))
		[headers setObject:mimeType forKey:@"Content-Type"];

	_percent = 0;
	_obuffer = [[NSMutableData alloc] init];//

	_request = [c createCFRequestForMethod:UPLOAD_HTTP_METHOD withResource:[b name] subResource:k headers:headers];
	_headerData = CFHTTPMessageCopySerializedMessage(_request);
	
	return self;
}

-(void)start:(id)sender
{
	NSHost *host = [NSHost hostWithName:DEFAULT_HOST];
	// _istream and _ostream are instance variables
	[NSStream getStreamsToHost:host port:80 inputStream:&_istream outputStream:&_ostream];
	_fstream = [NSInputStream inputStreamWithFileAtPath:_path];
    [_istream retain];
	[_ostream retain];
	[_fstream retain];
	
	[_istream setDelegate:self];
	[_ostream setDelegate:self];
	[_fstream setDelegate:self];
	[_istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_fstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_istream open];
    [_ostream open];
    [_fstream open];	
	[self setStatus:@"Active"];
	[self setActive:TRUE];
	[self setState:S3OperationActive];

}

+(S3ObjectStreamedUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k path:(NSString*)p acl:(NSString*)a mimeType:(NSString*)m
{
	return [[[S3ObjectStreamedUploadOperation alloc] initWithConnection:c delegate:d bucket:b key:k path:p acl:a mimeType:m] autorelease];;
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
	[_istream close];
	[_ostream close];
	[_fstream close];
	[_istream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_ostream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_fstream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_fstream release];
	[_istream release];
	[_ostream release];
	_istream = nil;
	_ostream = nil;
	_fstream = nil;
	[_ibuffer release];
	[_obuffer release];
	_ibuffer = nil;
	_obuffer = nil;
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
	[self setState:S3OperationError];
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
	[_path release];
	[_istream release];
	[_ostream release];
	[_fstream release];
	[_ibuffer release];
	[_obuffer release];
	if (_request!=NULL)
        CFRelease(_request);	
	if (_response!=NULL)
        CFRelease(_response);
	if (_headerData!=NULL)
        CFRelease(_headerData);
	[super dealloc];
}


- (void)connectionDidFinishLoading {
    [self setStatus:@"Done"];
	[self setActive:NO];
	[self setState:S3OperationDone];
	[_delegate operationDidFinish:self];
}


- (void)connectionDidFailWithError:(NSError *)error {
	[self setError:error];
    [self setStatus:@"Error"];
	[self setActive:NO];
	[self setState:S3OperationError];
	[_delegate operationDidFail:self];
}

#define FILEBUFFERSIZE 16

- (void)processFileBytes 
{
	if (![_fstream hasBytesAvailable])
		[_fstream close];
	else if ([_obuffer length]==0)
	{
		[_obuffer setLength:FILEBUFFERSIZE*1024];
		unsigned int read = [_fstream read:[_obuffer mutableBytes] maxLength:[_obuffer length]];
		[_obuffer setLength:read];
		if (read==0)
			[_fstream close];
	}
	//NSLog(@"F-> %d",[_fstream streamStatus]);
}
	
- (void)processOutgoingBytes {
	
    if (![_ostream hasSpaceAvailable]) {
        return;
    }
	
	if (_headerData!=NULL) 
	{
		int w = [_ostream write:CFDataGetBytePtr(_headerData) maxLength:CFDataGetLength(_headerData)];
		if (w < CFDataGetLength(_headerData))
			NSLog(@"Header data was not sent in just one write. Oops");
		CFRelease(_headerData);
		_headerData = NULL;
	}
	
    unsigned olen = [_obuffer length];
    if (0 < olen) {
        int writ = [_ostream write:[_obuffer bytes] maxLength:olen];

		_sent = _sent + writ;
		int percent = _sent * 100 / _size;
		if (_percent != percent) 
		{
			[self setStatus:[NSString stringWithFormat:@"Sending data %d %%",percent]];
			_percent = percent;
		}
        
        // buffer any unwritten bytes for later writing
		if (writ < olen) {
            memmove([_obuffer mutableBytes], [_obuffer mutableBytes] + writ, olen - writ);
            [_obuffer setLength:olen - writ];
            return;
        }
        [_obuffer setLength:0];
    }
	[self processFileBytes];
	
	
	if (0 == [_obuffer length]) 
	{
		if (([_fstream streamStatus]==NSStreamStatusAtEnd)||([_fstream streamStatus]==NSStreamStatusClosed)||([_fstream streamStatus]==NSStreamStatusError))
		{
			[_ostream close];
		}
	}		
	//NSLog(@"O-> %d",[_ostream streamStatus]);
}

- (BOOL)analyzeIncomingBytes {
    CFHTTPMessageRef working = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    CFHTTPMessageAppendBytes(working, [_ibuffer bytes], [_ibuffer length]);
    
	_response = working;
	CFRetain(_response);
			 
    CFRelease(working);
    return YES;
}


// We fake KVO for the inspector pane.

-(id)valueForUndefinedKey:(NSString*)k
{
	if ([k isEqualToString:@"response"])
		return self;
	if ([k isEqualToString:@"request"])
		return self;
	return [super valueForUndefinedKey:k];
}

- (id)valueForKeyPath:(NSString *)keyPath
{
	if ([keyPath isEqualToString:@"response.httpStatus"])
	{
		if (_response==NULL)
			return @"";
		int status = CFHTTPMessageGetResponseStatusCode(_response);
		return [NSString stringWithFormat:@"%d (%@)",status,[NSHTTPURLResponse localizedStringForStatusCode:status]];
	}
	if ([keyPath isEqualToString:@"response.headersReceived"])
	{
		NSMutableArray* a = [NSMutableArray array];
		if (_response==NULL)
			return a;
		CFDictionaryRef h = CFHTTPMessageCopyAllHeaderFields(_response);
		NSEnumerator* e = [(NSDictionary*)h keyEnumerator];
		NSString* k;
		while (k = [e nextObject])
		{
			[a addObject:[NSDictionary dictionaryWithObjectsAndKeys:k,@"key",[(NSDictionary*)h objectForKey:k],@"value",nil]];
		}
		CFRelease(h);
		return a;				
	}
	if ([keyPath isEqualToString:@"request.headersSent"])
	{
		NSMutableArray* a = [NSMutableArray array];
		if (_request==NULL)
			return a;
		CFDictionaryRef h = CFHTTPMessageCopyAllHeaderFields(_request);
		NSEnumerator* e = [(NSDictionary*)h keyEnumerator];
		NSString* k;
		while (k = [e nextObject])
		{
			[a addObject:[NSDictionary dictionaryWithObjectsAndKeys:k,@"key",[(NSDictionary*)h objectForKey:k],@"value",nil]];
		}
		CFRelease(h);
		return a;		
	}
	if ([keyPath isEqualToString:@"request.HTTPMethod"])
		return UPLOAD_HTTP_METHOD;
	if ([keyPath isEqualToString:@"request.URL"])
	{
		if (_request==NULL)
			return @"";
		return [[(NSURL*)CFHTTPMessageCopyRequestURL(_request) autorelease] description];
	}
		
	return [super valueForKeyPath:keyPath];
}


- (void)processIncomingBytes
{        
	if(!_ibuffer) {
		_ibuffer = [[NSMutableData data] retain];
	}
	uint8_t buf[1024];
	int len = 0;
	len = [_istream read:buf maxLength:1024];
	if(len>0) {
		[_ibuffer appendBytes:(const void *)buf length:len];
	} else {
		[_istream close];
	}
	if ([self analyzeIncomingBytes])
	{
		[_istream close];
		[self invalidate];
		if ([self operationSuccess])
			[self connectionDidFinishLoading];
		else
			[self connectionDidFailWithError:[self error]];
	}
	
	//NSLog(@"I-> %d",[_istream streamStatus]);
}	

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode 
{
#if 0
	if (stream==_fstream)
		NSLog(@"_fstream %d %d",eventCode,[stream streamStatus]);
	if (stream==_ostream)
		NSLog(@"_ostream %d %d",eventCode,[stream streamStatus]);
	if (stream==_istream)
		NSLog(@"_istream %d %d",eventCode,[stream streamStatus]);
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
			if (stream == _ostream)
				[self setStatus:@"Connected to server"];
			break;
        case NSStreamEventHasSpaceAvailable:
			if (stream == _ostream)
				[self processOutgoingBytes];
            break;
        case NSStreamEventHasBytesAvailable:
			if (stream == _istream)
				[self processIncomingBytes];
			else if (stream == _fstream)
				[self processFileBytes];
				break;
		case NSStreamEventEndEncountered:
			if (stream == _istream)
				[self analyzeIncomingBytes];
		default:
			break;
	}
}


@end
