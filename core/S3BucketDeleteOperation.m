//
//  S3BucketDeleteOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3BucketDeleteOperation.h"


@implementation S3BucketDeleteOperation

- (NSString*)kind
{
	return @"Bucket deletion";
}

+ (S3BucketDeleteOperation *)bucketDeletionWithConnection:(S3Connection *)c bucket:(S3Bucket *)b
{
	NSURLRequest *rootConn = [c makeRequestForMethod:@"DELETE" withResource:[b name]];
	S3BucketDeleteOperation *op = [[[S3BucketDeleteOperation alloc] initWithRequest:rootConn] autorelease];
	return op;
}

@end
