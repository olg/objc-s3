//
//  S3ObjectDeleteOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3ObjectDeleteOperation.h"


@implementation S3ObjectDeleteOperation

-(NSString*)kind
{
	return @"Object deletion";
}

+(S3ObjectDeleteOperation*)objectDeletionWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b object:(S3Object*)o;
{
	NSURLRequest* rootConn = [c makeRequestForMethod:@"DELETE" withResource:[c resourceForBucket:b key:[o key]]];
	S3ObjectDeleteOperation* op = [[[S3ObjectDeleteOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	return op;
}

@end