//
//  S3BucketListOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/1/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3BucketOperations.h"
#import "S3Owner.h"
#import "S3Connection.h"
#import "S3Bucket.h"
#import "S3Object.h"
#import "S3Extensions.h"



@implementation S3BucketAddOperation

-(NSString*)kind
{
	return @"Bucket addition";
}

+(S3BucketAddOperation*)bucketAddWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d name:(NSString*)name;
{
	NSURLRequest* rootConn = [c makeRequestForMethod:@"PUT" withResource:name];
	S3BucketAddOperation* op = [[[S3BucketAddOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	return op;
}

@end


@implementation S3BucketDeleteOperation

-(NSString*)kind
{
	return @"Bucket deletion";
}

+(S3BucketDeleteOperation*)bucketDeletionWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b;
{
	NSURLRequest* rootConn = [c makeRequestForMethod:@"DELETE" withResource:[b name]];
	S3BucketDeleteOperation* op = [[[S3BucketDeleteOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	return op;
}

@end


@implementation S3BucketListOperation

+(S3BucketListOperation*)bucketListOperationWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d
{
	NSURLRequest* rootConn = [c makeRequestForMethod:@"GET"];
	S3BucketListOperation* op = [[[S3BucketListOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	return op;
}

-(NSString*)kind
{
	return @"Bucket list";
}

-(S3Owner*)owner
{
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLDocumentTidyXML error:&_error] autorelease];
	NSArray* a = [[d rootElement] nodesForXPath:@"//Owner" error:&_error];
	if ([a count]==1)
		return [S3Owner ownerWithXMLNode:[a objectAtIndex:0]];
	else
		return nil;
}

-(NSMutableArray*)bucketList
{
	NSXMLElement* n;
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLDocumentTidyXML error:&_error] autorelease];

	NSEnumerator* e = [[[d rootElement] nodesForXPath:@"//Bucket" error:&_error] objectEnumerator];
	NSMutableArray* result = [NSMutableArray array];
	while (n=[e nextObject])
	{
		S3Bucket* b = [S3Bucket bucketWithXMLNode:n];
		if (b!=nil)
			[result addObject:b];
	}
	return result;
}

@end
