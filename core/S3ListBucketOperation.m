//
//  S3ListBucketOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 8/24/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3ListBucketOperation.h"
#import "S3Owner.h"
#import "S3Bucket.h"
#import "S3Extensions.h"

@implementation S3ListBucketOperation

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo
{
    self = [super initWithConnectionInfo:theConnectionInfo];
    
    if (self != nil) {
        
    }
    
    return self;
}

- (NSString *)kind
{
	return @"Bucket list";
}

- (NSString *)requestHTTPVerb
{
    return @"GET";
}

- (id)valueForUndefinedKey:(NSString *)akey
{
    NSLog(@"%@", akey);
    return nil;
}

- (S3Owner *)owner
{
    NSError *_error;
	NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:[self responseData] options:NSXMLNodeOptionsNone error:&_error] autorelease];
	NSArray *owners = [[d rootElement] nodesForXPath:@"//Owner" error:&_error];
    if ([owners count] == 1) {
        NSXMLElement *element = [owners objectAtIndex:0];

        NSArray *elements = nil;
        
        elements = [element elementsForName:@"ID"];
        NSString *ownerID = nil;
        if ([elements count] == 1) {
            ownerID = [[elements objectAtIndex:0] stringValue];            
        }
        
        elements = [element elementsForName:@"DisplayName"];
        NSString *name = nil;
        if ([elements count] == 1) {
            name = [[elements objectAtIndex:0] stringValue];            
        }
        
        S3Owner *owner = nil;
        if (name != nil) {
            owner = [[[S3Owner alloc] initWithID:ownerID displayName:name] autorelease];
        }
        
        return owner;        
    }
    
    return nil;
}

- (NSArray *)bucketList
{
    NSError *_error;
	NSXMLElement *element;
	NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:[self responseData] options:NSXMLNodeOptionsNone error:&_error] autorelease];
    
	NSEnumerator *e = [[[d rootElement] nodesForXPath:@"//Bucket" error:&_error] objectEnumerator];
    NSMutableArray *result = [NSMutableArray array];
    while (element = [e nextObject]) {
        
        NSString *name = [[element elementForName:@"Name"] stringValue];
        NSCalendarDate *date = [[element elementForName:@"CreationDate"] dateValue];
        S3Bucket *b = nil;
        if (name != nil) {
            b = [[[S3Bucket alloc] initWithName:name creationDate:date] autorelease];        
        }
        
        if (b != nil) {
            [result addObject:b];            
        }
    }
    
    return result;    
}

@end
