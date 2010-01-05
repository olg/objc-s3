//
//  S3AddBucketOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/20/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3AddBucketOperation.h"

#import "AWSRegion.h"
#import "S3Bucket.h"

static NSString *S3OperationInfoAddBucketOperationBucketKey = @"S3OperationInfoAddBucketOperationBucketKey";
static NSString *S3OperationInfoAddBucketOperationRegionKey = @"S3OperationInfoAddBucketOperationRegionKey";
static NSString *S3LocationFormatString = @"<CreateBucketConfiguration><LocationConstraint>%@</LocationConstraint></CreateBucketConfiguration>";

@implementation S3AddBucketOperation

@dynamic bucket;
@dynamic region;

- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci bucket:(S3Bucket *)b region:(AWSRegion *)r;
{    
    NSMutableDictionary *theOperationInfo = [[NSMutableDictionary alloc] init];
    if (b) {
        [theOperationInfo setObject:b forKey:S3OperationInfoAddBucketOperationBucketKey];        
    }
    if (r) {
        [theOperationInfo setObject:r forKey:S3OperationInfoAddBucketOperationRegionKey];
    }

    self = [super initWithConnectionInfo:ci operationInfo:theOperationInfo];
    
    [theOperationInfo release];

    if (self != nil) {
        if (!([r availableServices] & AWSSimpleStorageService)) {
            [self release];
            return nil;
        }        
    }
    
	return self;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci bucket:(S3Bucket *)b
{
    return [self initWithConnectionInfo:ci bucket:b region:nil];
}

- (S3Bucket *)bucket
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoAddBucketOperationBucketKey];
}

- (AWSRegion *)region
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoAddBucketOperationRegionKey];
}

- (NSString *)kind
{
	return @"Bucket addition";
}

- (NSString *)requestHTTPVerb
{
    return @"PUT";
}

- (BOOL)virtuallyHostedCapable
{
	return [[self bucket] virtuallyHostedCapable];
}

- (NSString *)bucketName
{
    return [[self bucket] name];
}

- (NSData *)requestBodyContentData
{
    AWSRegion *region = [self region];
    if (region != nil) {
        return [[NSString stringWithFormat:S3LocationFormatString, [region regionValue]] dataUsingEncoding:NSASCIIStringEncoding];
    }    
    return nil;
}

- (NSUInteger)requestBodyContentLength
{
    NSData *contents = [self requestBodyContentData];
    if (!contents) {
        return 0;
    }
    return [contents length];
}

@end
