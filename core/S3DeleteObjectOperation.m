//
//  S3DeleteObjectOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/26/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3DeleteObjectOperation.h"

#import "S3ConnectionInfo.h"
#import "S3Bucket.h"
#import "S3Object.h"

static NSString *S3OperationInfoDeleteObjectOperationObjectKey = @"S3OperationInfoDeleteObjectOperationObjectKey";

@implementation S3DeleteObjectOperation

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o
{
    NSMutableDictionary *theOperationInfo = [[NSMutableDictionary alloc] init];
    if (o) {
        [theOperationInfo setObject:o forKey:S3OperationInfoDeleteObjectOperationObjectKey];
    }
    
    self = [super initWithConnectionInfo:c operationInfo:theOperationInfo];
    
    [theOperationInfo release];
    
    if (self != nil) {
        
    }
    
	return self;
}

- (S3Object *)object 
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoDeleteObjectOperationObjectKey];
}

- (NSString *)kind
{
	return @"Object deletion";
}

- (NSString *)requestHTTPVerb
{
    return @"DELETE";
}

- (BOOL)virtuallyHostedCapable
{
	return [[[self object] bucket] virtuallyHostedCapable];
}

- (NSString *)bucketName
{
    S3Object *object = [self object];

    return [[object bucket] name];
}

- (NSString *)key
{
    S3Object *object = [self object];

    return [object key];
}

@end
