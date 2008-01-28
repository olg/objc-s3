//
//  S3BucketAddOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3BucketAddOperation.h"

#define EUROPE_SETUP @"<CreateBucketConfiguration><LocationConstraint>EU</LocationConstraint></CreateBucketConfiguration>"


@implementation S3BucketAddOperation

- (NSString *)kind
{
	return @"Bucket addition";
}

+ (S3BucketAddOperation *)bucketAddWithConnection:(S3Connection *)c name:(NSString *)name europeConstraint:(bool)b
{
    NSURLRequest *rootConn;
    if (b)
        rootConn = [c makeRequestForMethod:@"PUT" withResource:name headers:nil data:[EUROPE_SETUP dataUsingEncoding:NSUTF8StringEncoding]];
    else
        rootConn = [c makeRequestForMethod:@"PUT" withResource:name];
	S3BucketAddOperation *op = [[[S3BucketAddOperation alloc] initWithRequest:rootConn] autorelease];
	return op;
}

@end

