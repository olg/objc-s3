//
//  S3ObjectOperations.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/9/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ObjectOperations.h"
#import "S3Owner.h"
#import "S3Connection.h"
#import "S3Bucket.h"
#import "S3Object.h"
#import "S3Extensions.h"

#define XAMZACL @"x-amz-acl"

@implementation S3ObjectDeleteOperation

-(NSString*)kind
{
	return @"Object deletion";
}

+(S3ObjectDeleteOperation*)objectDeletionWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b object:(S3Object*)o;
{
	NSURLRequest* rootConn = [c makeRequestForMethod:@"DELETE" withResource:[b name] subResource:[o key]];
	S3ObjectDeleteOperation* op = [[[S3ObjectDeleteOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	return op;
}

@end

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

@implementation S3ObjectListOperation

-(void)dealloc
{
	[_bucket release];
	[super dealloc];
}

-(NSString*)kind
{
	return @"Bucket content";
}

- (S3Bucket *)bucket
{
    return _bucket; 
}

- (void)setBucket:(S3Bucket *)aBucket
{
    [_bucket release];
    _bucket = [aBucket retain];
}

+(S3ObjectListOperation*)objectListWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b;
{
	NSURLRequest* rootConn = [c makeRequestForMethod:@"GET" withResource:[b name]];
	S3ObjectListOperation* op = [[[S3ObjectListOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	[op setBucket:b];
	return op;
}

-(NSMutableDictionary*)metadata
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLDocumentTidyXML error:&_error] autorelease];
	NSXMLElement* root = [d rootElement];
	
	[dictionary safeSetObject:[[root elementForName:@"Name"] stringValue] forKey:@"Name"];
	[dictionary safeSetObject:[[root elementForName:@"Marker"] stringValue] forKey:@"Marker"];
	[dictionary safeSetObject:[[root elementForName:@"MaxKeys"] stringValue] forKey:@"MaxKeys"];
	[dictionary safeSetObject:[[root elementForName:@"Prefix"] stringValue] forKey:@"Prefix"];
	[dictionary safeSetObject:[[root elementForName:@"IsTruncated"] stringValue] forKey:@"IsTruncated"];
	
	return dictionary;
}

-(NSMutableArray*)objects
{
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLDocumentTidyXML error:&_error] autorelease];
	NSXMLElement* root = [d rootElement];
	NSXMLElement* n;
	
	NSEnumerator* e = [[root nodesForXPath:@"//Contents" error:&_error] objectEnumerator];
	NSMutableArray* result = [NSMutableArray array];
	while (n=[e nextObject])
	{
		S3Object* b = [S3Object objectWithXMLNode:n];
		if (b!=nil) {
			[result addObject:b];
			[b setBucket:_bucket];
		}
	}
	return result;
}

@end



