//
//  S3ObjectListOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3ObjectListOperation.h"
#import "S3Object.h"
#import "S3Extensions.h"


@implementation S3ObjectListOperation

-(void)dealloc
{
	[_bucket release];
	[super dealloc];
}

-(NSString*)kind
{
	return @"Bucket content";
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

- (S3Connection *)connection
{
    return _s3connection; 
}

- (void)setConnection:(S3Connection *)aConnection
{
    [aConnection retain];
    [_connection release];
    _s3connection = aConnection;
}

+(S3ObjectListOperation*)objectListWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b
{
    return [S3ObjectListOperation objectListWithConnection:c delegate:d bucket:b marker:nil];
}

+(S3ObjectListOperation*)objectListWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b marker:(NSString*)marker
{
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params safeSetObject:marker forKey:@"marker"];
    
	NSURLRequest* rootConn = [c makeRequestForMethod:@"GET" withResource:[c resourceForBucket:b parameters:[params queryString]] headers:nil];
	S3ObjectListOperation* op = [[[S3ObjectListOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
    [op setConnection:c];
	[op setBucket:b];
	return op;
}

-(NSMutableDictionary*)metadata
{
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLNodeOptionsNone error:&_error] autorelease];
	NSXMLElement* root = [d rootElement];
	
	[dictionary safeSetObject:[[root elementForName:@"Name"] stringValue] forKey:@"Name"];
	[dictionary safeSetObject:[[root elementForName:@"Marker"] stringValue] forKey:@"Marker"];
	[dictionary safeSetObject:[[root elementForName:@"NextMarker"] stringValue] forKey:@"NextMarker"];
	[dictionary safeSetObject:[[root elementForName:@"MaxKeys"] stringValue] forKey:@"MaxKeys"];
	[dictionary safeSetObject:[[root elementForName:@"Prefix"] stringValue] forKey:@"Prefix"];
	[dictionary safeSetObject:[[root elementForName:@"IsTruncated"] stringValue] forKey:@"IsTruncated"];
	
	return dictionary;
}

-(S3ObjectListOperation*)operationForNextChunk
{
    NSDictionary* d = [self metadata];
    if (![[d objectForKey:@"IsTruncated"] isEqualToString:@"true"])
        return nil;
    
    NSString* nm = [d objectForKey:@"NextMarker"];
    if (nm==nil)
    {
        NSArray* objs = [self objects];
        nm = [[objs objectAtIndex:([objs count]-1)] key];
    }
    
    if (nm==nil)
        return nil;
    
    S3ObjectListOperation* op = [S3ObjectListOperation objectListWithConnection:[self connection] delegate:_delegate bucket:_bucket marker:nm];
    return op;
}

-(NSMutableArray*)objects
{
	NSXMLDocument* d = [[[NSXMLDocument alloc] initWithData:_data options:NSXMLNodeOptionsNone error:&_error] autorelease];
	NSXMLElement* root = [d rootElement];
	NSXMLElement* n;
	
	NSEnumerator* e = [[root nodesForXPath:@"//Contents" error:&_error] objectEnumerator];
        NSMutableArray* result = [NSMutableArray array];
        while (n=[e nextObject])
        {
            S3Object* b = [S3Object objectWithXMLNode:n];
            if (b!=nil) {
                [result addObject:b];
                [b setBucket:_bucket];
            }
        }
        return result;
}

@end

