//
//  S3BucketAddOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3BucketAddOperation.h"


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

