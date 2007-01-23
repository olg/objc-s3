//
//  S3BucketDeleteOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3BucketDeleteOperation.h"


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
