//
//  S3DeleteBucketOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/20/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3DeleteBucketOperation.h"

@interface S3DeleteBucketOperation ()
@property(readwrite, retain) S3Bucket *bucket;
@end

@implementation S3DeleteBucketOperation

@synthesize bucket = _bucket;

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)b
{
    self = [super initWithConnectionInfo:theConnectionInfo];
    
    if (self != nil) {
        [self setBucket:b];
    }
    
    return self;
}

- (NSString *)requestHTTPVerb
{
    return @"DELETE";
}

- (NSString *)bucketName
{
    return [[self bucket] name];
}

- (NSString*)kind
{
	return @"Bucket deletion";
}


@end
