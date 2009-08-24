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

@interface S3DownloadObjectOperation ()

@property(readwrite, retain) S3Object *object;
@property(readwrite, copy) NSString *filePath;

@end

@implementation S3DownloadObjectOperation

@synthesize object = _object;
@synthesize filePath = _filePath;

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o saveTo:(NSString *)filePath
{
    self = [super initWithConnectionInfo:c];
    
    if (self != nil) {
        [self setObject:o];
        [self setFilePath:filePath];
    }
    
    return self;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o
{
    return [self initWithConnectionInfo:c object:o saveTo:nil];
}

- (NSString *)requestHTTPVerb
{
    return @"GET";
}

- (NSString *)bucketName
{
    return [[[self object] bucket] name];
}

- (NSString *)key
{
    return [[self object] key];
}

- (NSString *)responseBodyContentFilePath
{
    return [self filePath];
}

- (long long)responseBodyContentExepctedLength
{
    NSString *lengthString = [[[self object] metadata] objectForKey:S3ObjectMetadataContentLengthKey];
    long long lengthNumber = 0;
    if (lengthString != nil) {
        lengthNumber = [lengthString longLongValue];
    }
    
    return lengthNumber;
}

- (NSString *)kind
{
	return @"Object download";
}

@end
