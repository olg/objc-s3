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

@interface S3AddObjectOperation ()

@property(readwrite, retain) S3Object *object;

@end

@implementation S3AddObjectOperation

@synthesize object = _object;

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o
{
    self = [super initWithConnectionInfo:c];
    
    if (self != nil) {
        [self setObject:o];
    }
    
	return self;
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
    return [[self object] metadata];
}

- (NSString *)bucketName
{
    return [[[self object] bucket] name];
}

- (NSString *)key
{
    return [[self object] key];
}

- (NSDictionary *)requestQueryItems
{
    return nil;
}

- (NSString *)requestBodyContentMD5
{
    return [[[self object] metadata] objectForKey:S3ObjectMetadataContentMD5Key];
}

- (NSData *)requestBodyContentData
{
    return [[[self object] dataSourceInfo] objectForKey:S3ObjectNSDataSourceKey];
}

- (NSString *)requestBodyContentFilePath
{
    return [[[self object] dataSourceInfo] objectForKey:S3ObjectFilePathDataSourceKey];
}

- (NSString *)requestBodyContentType
{
    return [[[self object] metadata] objectForKey:S3ObjectMetadataContentTypeKey];
}

- (long long)requestBodyContentLength
{
    NSNumber *length = [[[self object] metadata] objectForKey:S3ObjectMetadataContentLengthKey];
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
