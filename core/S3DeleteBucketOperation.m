//
//  S3DeleteBucketOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/20/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3DeleteBucketOperation.h"

static NSString *S3OperationInfoDeleteBucketOperationBucketKey = @"S3OperationInfoDeleteBucketOperationBucketKey";

@implementation S3DeleteBucketOperation

@dynamic bucket;

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)b
{
    NSMutableDictionary *theOperationInfo = [[NSMutableDictionary alloc] init];
    if (b) {
        [theOperationInfo setObject:b forKey:S3OperationInfoDeleteBucketOperationBucketKey];
    }
    
    self = [super initWithConnectionInfo:theConnectionInfo operationInfo:theOperationInfo];
    
    [theOperationInfo release];
    
    if (self != nil) {
        
    }
    
	return self;
}

- (S3Bucket *)bucket
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoDeleteBucketOperationBucketKey];
}

- (NSString*)kind
{
	return @"Bucket deletion";
}

- (NSString *)requestHTTPVerb
{
    return @"DELETE";
}

- (BOOL)virtuallyHostedCapable
{
	return [[self bucket] virtuallyHostedCapable];
}

- (NSString *)bucketName
{
    return [[self bucket] name];
}

@end
