//
//  S3AddBucketOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/20/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3AddBucketOperation.h"
#import "S3Bucket.h"

NSString *S3LocationFormatString = @"<CreateBucketConfiguration><LocationConstraint>%@</LocationConstraint></CreateBucketConfiguration>";

@interface S3AddBucketOperation ()
@property(readwrite, retain) S3Bucket *bucket;
@property(readwrite, copy) NSString *location;
@property(readwrite, copy) NSString *locationConstraint;
@end

@implementation S3AddBucketOperation

@synthesize bucket = _bucket;
@synthesize location = _location;
@synthesize locationConstraint = _locationConstraint;

- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci bucket:(S3Bucket *)b location:(NSString *)l;
{
    self = [super initWithConnectionInfo:ci];
    
    if (self != nil) {
        [self setBucket:b];
        [self setLocation:l];
        if ([self location] != nil) {
            [self setLocationConstraint:[NSString stringWithFormat:S3LocationFormatString, [self location]]];
        }
    }
    
	return self;
}

- (void)dealloc
{
    [_bucket release];
    [_location release];
    [_locationConstraint release];
    
    [super dealloc];
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci bucket:(S3Bucket *)b
{
    return [self initWithConnectionInfo:ci bucket:b location:nil];
}

- (NSString *)requestHTTPVerb
{
    return @"PUT";
}

- (NSString *)bucketName
{
    return [[self bucket] name];
}

- (NSData *)requestBodyContentData
{
    if ([self locationConstraint] != nil) {
        return [[self locationConstraint] dataUsingEncoding:NSASCIIStringEncoding];
    }
    return nil;
}

- (long long)requestBodyContentLength
{
    return [[self locationConstraint] lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
}

- (NSString *)kind
{
	return @"Bucket addition";
}

@end
