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

static NSString *S3OperationInfoListObjectOperationBucketKey = @"S3OperationInfoListObjectOperationBucketKey";
static NSString *S3OperationInfoListObjectOperationMarkerKey = @"S3OperationInfoListObjectOperationMarkerKey";

@implementation S3ListObjectOperation

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)theBucket marker:(NSString *)theMarker
{
    NSMutableDictionary *theOperationInfo = [[NSMutableDictionary alloc] init];
    if (theBucket) {
        [theOperationInfo setObject:theBucket forKey:S3OperationInfoListObjectOperationBucketKey];
    }
    if (theMarker) {
        [theOperationInfo setObject:theMarker forKey:S3OperationInfoListObjectOperationMarkerKey];
    }
    
    self = [super initWithConnectionInfo:theConnectionInfo operationInfo:theOperationInfo];
    
    [theOperationInfo release];
    
    if (self != nil) {
        
    }
    
	return self;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)theBucket
{
    return [self initWithConnectionInfo:theConnectionInfo bucket:theBucket marker:nil];
}

- (S3Bucket *)bucket
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoListObjectOperationBucketKey];
}

- (NSString *)marker
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoListObjectOperationMarkerKey];
}

- (NSString *)kind
{
	return @"Bucket content";
}

- (NSString *)requestHTTPVerb
{
    return @"GET";
}

- (NSString *)bucketName
{
    return [[self bucket] name];
}

- (NSDictionary *)requestQueryItems
{
    NSString *marker = [self marker];
    if (marker != nil) {
        return [NSDictionary dictionaryWithObjectsAndKeys:marker, @"marker", nil];
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
        
        S3Bucket *bucket = [self bucket];
        S3Object *newObject = [[S3Object alloc] initWithBucket:bucket key:resultKey userDefinedMetadata:nil metadata:metadata dataSourceInfo:nil];
        
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
    
    S3Bucket *bucket = [self bucket];
    S3ListObjectOperation *op = [[[S3ListObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] bucket:bucket marker:nm] autorelease];
    
    return op;
}

@end
