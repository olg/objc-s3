//
//  S3ListObjectOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/19/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3ListObjectOperation.h"
#import "S3Extensions.h"
#import "S3Owner.h"
#import "S3Bucket.h"
#import "S3Object.h"

@interface S3ListObjectOperation ()
@property(readwrite, retain) S3Bucket *bucket;
@property(readwrite, copy) NSString *marker;
@end

@implementation S3ListObjectOperation

@synthesize bucket = _bucket;
@synthesize marker = _marker;

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)theBucket marker:(NSString *)marker
{
    self = [super initWithConnectionInfo:theConnectionInfo];
    if (self != nil) {
        [self setBucket:theBucket];
        [self setMarker:marker];
    }
    return self;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)theBucket
{
    return [self initWithConnectionInfo:theConnectionInfo bucket:theBucket marker:nil];
}

- (NSString *)requestHTTPVerb
{
    return @"GET";
}

- (NSString *)bucketName
{
    return [[self bucket] name];
}

- (NSString *)kind
{
	return @"Bucket content";
}

- (NSDictionary *)requestQueryItems
{
    if ([self marker] != nil) {
        return [NSDictionary dictionaryWithObjectsAndKeys:[self marker], @"marker", nil];
    }
    return nil;
}

- (NSMutableDictionary *)metadata
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSError *_error;
	NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:[self responseData] options:NSXMLNodeOptionsNone error:&_error] autorelease];
	NSXMLElement *root = [d rootElement];
	
	[dictionary safeSetObject:[[root elementForName:@"Name"] stringValue] forKey:@"Name"];
	[dictionary safeSetObject:[[root elementForName:@"Marker"] stringValue] forKey:@"Marker"];
	[dictionary safeSetObject:[[root elementForName:@"NextMarker"] stringValue] forKey:@"NextMarker"];
	[dictionary safeSetObject:[[root elementForName:@"MaxKeys"] stringValue] forKey:@"MaxKeys"];
	[dictionary safeSetObject:[[root elementForName:@"Prefix"] stringValue] forKey:@"Prefix"];
	[dictionary safeSetObject:[[root elementForName:@"IsTruncated"] stringValue] forKey:@"IsTruncated"];
	
	return dictionary;
}

- (NSArray *)objects
{
    NSError *_error;
	NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:[self responseData] options:NSXMLNodeOptionsNone error:&_error] autorelease];
	NSXMLElement *root = [d rootElement];
	NSXMLElement *n;
    
	NSEnumerator *e = [[root nodesForXPath:@"//Contents" error:&_error] objectEnumerator];
    NSMutableArray *result = [NSMutableArray array];
    while (n = [e nextObject]) {        
        NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
        
        NSString *resultEtag = [[n elementForName:@"ETag"] stringValue];
        if (resultEtag != nil) {
            [metadata setObject:resultEtag forKey:S3ObjectMetadataETagKey];
        }
        
        NSCalendarDate *resultLastModified = [[n elementForName:@"LastModified"] dateValue];
        if (resultLastModified != nil) {
            [metadata setObject:resultLastModified forKey:S3ObjectMetadataLastModifiedKey];
        }
        
        NSNumber *resultSize = [[n elementForName:@"Size"] longLongNumber];
        if (resultSize != nil) {
            [metadata setObject:resultSize forKey:S3ObjectMetadataContentLengthKey];
        }
        
        NSXMLElement *ownerElement = [n elementForName:@"Owner"];
        NSArray *itemsArray = [ownerElement elementsForName:@"ID"];
        NSString *ownerID = nil;
        if ([itemsArray count] == 1) {
            ownerID = [[itemsArray objectAtIndex:0] stringValue];            
        }
        
        itemsArray = [ownerElement elementsForName:@"DisplayName"];
        NSString *name = nil;
        if ([itemsArray count] == 1) {
            name = [[itemsArray objectAtIndex:0] stringValue];            
        }
        
        S3Owner *resultOwner = nil;
        if (name != nil) {
            resultOwner = [[[S3Owner alloc] initWithID:ownerID displayName:name] autorelease];            
        }
        
        if (resultOwner != nil) {
            [metadata setObject:resultOwner forKey:S3ObjectMetadataOwnerKey];
        }
        
        NSString *resultStorageClass = [[n elementForName:@"StorageClass"] stringValue];
        if (resultStorageClass != nil) {
            [metadata setObject:resultStorageClass forKey:S3ObjectMetadataStorageClassKey];
        }
        
        NSString *resultKey = [[n elementForName:@"Key"] stringValue];
        
        S3Object *newObject = [[S3Object alloc] initWithBucket:[self bucket] key:resultKey userDefinedMetadata:nil metadata:metadata dataSourceInfo:nil];
        
        if (newObject != nil) {
            [result addObject:newObject];
        }
        [newObject release];
    }
    
    return result;    
}

- (S3ListObjectOperation *)operationForNextChunk
{
    NSDictionary *d = [self metadata];
    if (![[d objectForKey:@"IsTruncated"] isEqualToString:@"true"])
        return nil;
    
    NSString *nm = [d objectForKey:@"NextMarker"];
    if (nm==nil)
    {
        NSArray *objs = [self objects];
        nm = [[objs objectAtIndex:([objs count]-1)] key];
    }
    
    if (nm==nil)
        return nil;
    
    S3ListObjectOperation *op = [[[S3ListObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] bucket:[self bucket] marker:nm] autorelease];
    
    return op;
}

@end
