//
//  S3BucketListOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3BucketListOperation.h"
#import "S3Owner.h"
#import "S3Bucket.h"

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
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLNodeOptionsNone error:&_error] autorelease];
	NSArray* a = [[d rootElement] nodesForXPath:@"//Owner" error:&_error];
        if ([a count]==1)
            return [S3Owner ownerWithXMLNode:[a objectAtIndex:0]];
	else
		return nil;
}

-(NSMutableArray*)bucketList
{
	NSXMLElement* n;
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLNodeOptionsNone error:&_error] autorelease];
    
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
