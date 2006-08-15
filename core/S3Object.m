//
//  S3Object.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Object.h"
#import "S3Connection.h"
#import "S3Bucket.h"
#import "S3Owner.h"
#import "S3Extensions.h"


@implementation S3Object

-(id)initWithData:(NSData*)data metaData:(NSDictionary*)dict;
{
	[super init];
	[data retain];
	[dict retain];
	_data = data;
	_metadata = [[NSMutableDictionary dictionaryWithDictionary:dict] retain];
	return self;
}

-(void)dealloc
{
	[_data release];
	[_metadata release];
	[_bucket release];
	[super dealloc];
}

+(S3Object*)objectWithXMLNode:(NSXMLElement*)element
{
	NSMutableDictionary* d = [NSMutableDictionary dictionary];
	
	[d safeSetObject:[[element elementForName:@"Key"] stringValue] forKey:@"key"];
	[d safeSetObject:[[element elementForName:@"LastModified"] dateValue] forKey:@"lastModified"];
	[d safeSetObject:[[element elementForName:@"ETag"] stringValue] forKey:@"etag"];
	[d safeSetObject:[[element elementForName:@"Size"] longLongNumber] forKey:@"size"];
	[d safeSetObject:[[element elementForName:@"StorageClass"] stringValue] forKey:@"storageClass"];
	[d safeSetObject:[S3Owner ownerWithXMLNode:[element elementForName:@"Owner"]] forKey:@"owner"];

	return [[[S3Object alloc] initWithData:nil metaData:d] autorelease];
}

-(long long)size
{
	NSNumber* n = [_metadata objectForKey:@"size"];
	if (n==nil)
		return -1;
	else
		return [n longLongValue];
}

-(NSString*)key
{
	return [_metadata objectForKey:@"key"];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	id o = [_metadata objectForKey:key];
	if (o!=nil)
		return o;
	else
		return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	[_metadata safeSetObject:value forKey:key];
}


- (NSData *)data
{
    return _data; 
}

- (void)setData:(NSData *)aData
{
    [_data release];
    _data = [aData retain];
}

- (NSDictionary *)metadata
{
    return _metadata; 
}

- (void)setMetadata:(NSDictionary *)aMetadata
{
    [_metadata release];
    _metadata = [aMetadata retain];
}


- (S3Bucket *)bucket
{
    return _bucket; 
}

- (void)setBucket:(S3Bucket *)aBucket
{
    [_bucket release];
    _bucket = [aBucket retain];
}

@end
