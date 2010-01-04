//
//  S3DownloadObjectOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/30/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3DownloadObjectOperation.h"

#import "S3ConnectionInfo.h"
#import "S3Bucket.h"
#import "S3Object.h"

static NSString *S3OperationInfoDownloadObjectOperationObjectKey = @"S3OperationInfoDownloadObjectOperationObjectKey";
static NSString *S3OperationInfoDownloadObjectOperationFilePathKey = @"S3OperationInfoDownloadObjectOperationFilePathKey";

@implementation S3DownloadObjectOperation

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o saveTo:(NSString *)filePath
{
    NSMutableDictionary *theOperationInfo = [[NSMutableDictionary alloc] init];
    if (o) {
        [theOperationInfo setObject:o forKey:S3OperationInfoDownloadObjectOperationObjectKey];
    }
    if (filePath) {
        [theOperationInfo setObject:filePath forKey:S3OperationInfoDownloadObjectOperationFilePathKey];
    }
    
    self = [super initWithConnectionInfo:c operationInfo:theOperationInfo];
    
    [theOperationInfo release];
    
    if (self != nil) {
        
    }
    
	return self;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o
{
    return [self initWithConnectionInfo:c object:o saveTo:nil];
}

- (S3Object *)object
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoDownloadObjectOperationObjectKey];
}

- (NSString *)filePath
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoDownloadObjectOperationFilePathKey];
}

- (NSString *)kind
{
	return @"Object download";
}

- (NSString *)requestHTTPVerb
{
    return @"GET";
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

- (NSString *)responseBodyContentFilePath
{
    return [self filePath];
}

- (long long)responseBodyContentExepctedLength
{
    S3Object *object = [self object];
    
    NSString *lengthString = [[object metadata] objectForKey:S3ObjectMetadataContentLengthKey];
    long long lengthNumber = 0;
    if (lengthString != nil) {
        lengthNumber = [lengthString longLongValue];
    }
    
    return lengthNumber;
}

@end
