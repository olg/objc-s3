//
//  S3AddObjectOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/26/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3AddObjectOperation.h"

#import "S3ConnectionInfo.h"
#import "S3Bucket.h"
#import "S3Object.h"
#import "S3Extensions.h"

static NSString *S3OperationInfoAddObjectOperationObjectKey = @"S3OperationInfoAddObjectOperationObjectKey";

@implementation S3AddObjectOperation

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o
{
    NSMutableDictionary *theOperationInfo = [[NSMutableDictionary alloc] init];
    if (o) {
        [theOperationInfo setObject:o forKey:S3OperationInfoAddObjectOperationObjectKey];
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
    return [theOperationInfo objectForKey:S3OperationInfoAddObjectOperationObjectKey];
}

- (NSString *)kind
{
	return @"Object upload";
}

- (NSString *)requestHTTPVerb
{
    return @"PUT";
}

- (NSDictionary *)additionalHTTPRequestHeaders
{
    S3Object *object = [self object];
        
    return [object metadata];
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

- (NSDictionary *)requestQueryItems
{
    return nil;
}

- (NSString *)requestBodyContentMD5
{
    S3Object *object = [self object];
    
    return [[object metadata] objectForKey:S3ObjectMetadataContentMD5Key];
}

- (NSData *)requestBodyContentData
{
    S3Object *object = [self object];
    
    return [[object dataSourceInfo] objectForKey:S3ObjectNSDataSourceKey];
}

- (NSString *)requestBodyContentFilePath
{
    S3Object *object = [self object];
    
    return [[object dataSourceInfo] objectForKey:S3ObjectFilePathDataSourceKey];
}

- (NSString *)requestBodyContentType
{
    S3Object *object = [self object];
    
    return [[object metadata] objectForKey:S3ObjectMetadataContentTypeKey];
}

- (NSUInteger)requestBodyContentLength
{
    S3Object *object = [self object];
    
    NSNumber *length = [[object metadata] objectForKey:S3ObjectMetadataContentLengthKey];
    if (length != nil) {
        return [length unsignedIntegerValue];
    }

    if ([self requestBodyContentData] != nil) {
        return [[self requestBodyContentData] length]; 
    } else if ([self requestBodyContentFilePath] != nil) {
        return [[[self requestBodyContentFilePath] fileSizeForPath] longLongValue];
    }

    return 0;
}

@end
