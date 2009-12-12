//
//  S3Object.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Object.h"
#import "S3Bucket.h"
#import "S3Owner.h"
#import "S3Extensions.h"
#import "S3ListObjectOperation.h"

NSString *S3ObjectFilePathDataSourceKey = @"S3ObjectFilePathDataSourceKey";
NSString *S3ObjectNSDataSourceKey = @"S3ObjectNSDataSourceKey";

NSString *S3UserDefinedObjectMetadataPrefixKey = @"x-amz-meta-";
NSString *S3UserDefinedObjectMetadataMissingKey = @"x-amz-missing-meta";
NSString *S3ObjectMetadataACLKey = @"x-amz-acl";
NSString *S3ObjectMetadataContentMD5Key = @"content-md5";
NSString *S3ObjectMetadataContentTypeKey = @"content-type";
NSString *S3ObjectMetadataContentLengthKey = @"content-length";
NSString *S3ObjectMetadataETagKey = @"etag";
NSString *S3ObjectMetadataLastModifiedKey = @"last-modified";
NSString *S3ObjectMetadataOwnerKey = @"owner";
NSString *S3ObjectMetadataStorageClassKey = @"storageclass";

@interface S3Object ()

@property(readwrite, retain) S3Bucket *bucket;
@property(readwrite, copy) NSString *key;
@property(readwrite, copy) NSDictionary *userDefinedMetadata;
@property(readwrite, copy) NSDictionary *metadata;
@property(readwrite, copy) NSDictionary *dataSourceInfo;

@end


@implementation S3Object

@synthesize bucket = _bucket;
@synthesize key = _key;
@synthesize metadata = _metadata;
@synthesize dataSourceInfo = _dataSourceInfo;

- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd metadata:(NSDictionary *)md dataSourceInfo:(NSDictionary *)info
{
    self = [super init];
    
    if (self != nil) {
        [self setKey:key];
        [self setBucket:bucket];
        NSMutableDictionary *processedMetadata = [NSMutableDictionary dictionaryWithCapacity:[md count]];
        NSEnumerator *metadataKeyEnumerator = [md keyEnumerator];
        NSString *key = nil;
        while (key = [metadataKeyEnumerator nextObject]) {
            NSString *cleanedKey = [key lowercaseString];
            id object = [md objectForKey:key];
            [processedMetadata setObject:object forKey:cleanedKey];
        }
        [self setMetadata:[NSDictionary dictionaryWithDictionary:processedMetadata]];
        [self setUserDefinedMetadata:udmd];
        [self setDataSourceInfo:info];
    }
    
    return self;
}

- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd metadata:(NSDictionary *)md
{
    return [self initWithBucket:bucket key:key userDefinedMetadata:udmd metadata:md dataSourceInfo:nil];
}

- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd
{
    return [self initWithBucket:bucket key:key userDefinedMetadata:udmd metadata:nil];
}

- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key
{
    return [self initWithBucket:bucket key:key userDefinedMetadata:nil];
}

- (void)dealloc
{
	[_bucket release];
    [_key release];
	[_dataSourceInfo release];
	[_metadata release];
	[super dealloc];
}

- (NSDictionary *)userDefinedMetadata
{
    NSMutableDictionary *mutableDictionary = [[[NSMutableDictionary alloc] init] autorelease];
    NSString *metadataKey = nil;
    NSEnumerator *metadataKeyEnumerator = [[self metadata] keyEnumerator];
    NSRange notFoundRange = NSMakeRange(NSNotFound, 0);
    while (metadataKey = [metadataKeyEnumerator nextObject]) {
        NSRange foundRange = [metadataKey rangeOfString:S3UserDefinedObjectMetadataPrefixKey options:NSAnchoredSearch];
        if ([metadataKey isKindOfClass:[NSString class]] == YES && NSEqualRanges(foundRange, notFoundRange) == NO) {
            id object = [[self metadata] objectForKey:metadataKey];
            NSString *userDefinatedMetadataKey = [metadataKey stringByReplacingCharactersInRange:foundRange withString:@""];
            [mutableDictionary setObject:object forKey:userDefinatedMetadataKey];
        }
    }
    return [[mutableDictionary copy] autorelease];
}

- (void)setUserDefinedMetadata:(NSDictionary *)md
{
    NSMutableDictionary *mutableMetadata = [[self metadata] mutableCopy];
    NSString *metadataKey = nil;
    NSEnumerator *metadataKeyEnumerator = [md keyEnumerator];
    while (metadataKey = [metadataKeyEnumerator nextObject]) {
        if ([metadataKey isKindOfClass:[NSString class]] == YES) {
            id object = [md objectForKey:metadataKey];
            NSString *modifiedMetadataKey = [NSString stringWithFormat:@"%@%@", S3UserDefinedObjectMetadataPrefixKey, metadataKey];
            [mutableMetadata setObject:object forKey:modifiedMetadataKey];
        }
    }
    [self setMetadata:mutableMetadata];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    id o = [[self metadata] objectForKey:key];
	if (o != nil) {
		return o;        
    }

    return [super valueForUndefinedKey:key];
}

- (NSString *)acl
{
    return [[self metadata] objectForKey:S3ObjectMetadataACLKey];
}

- (NSString *)contentMD5
{
    return [[self metadata] objectForKey:S3ObjectMetadataContentMD5Key];
}

- (NSString *)contentType
{
    return [[self metadata] objectForKey:S3ObjectMetadataContentTypeKey];
}

- (NSString *)contentLength
{
    return [[self metadata] objectForKey:S3ObjectMetadataContentLengthKey];
}

- (NSString *)etag
{
    return [[self metadata] objectForKey:S3ObjectMetadataETagKey];
}

- (NSString *)lastModified
{
    return [[self metadata] objectForKey:S3ObjectMetadataLastModifiedKey];
}

- (S3Owner *)owner
{
    return [[self metadata] objectForKey:S3ObjectMetadataOwnerKey];
}

- (NSString *)storageClass
{
    return [[self metadata] objectForKey:S3ObjectMetadataStorageClassKey];
}

- (BOOL)missingMetadata;
{
    id object = [[self metadata] objectForKey:S3UserDefinedObjectMetadataMissingKey];
    return (object == nil ? NO : YES);
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

@end
