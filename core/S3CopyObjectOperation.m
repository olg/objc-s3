//
//  S3CopyObjectOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 12/11/09.
//  Copyright 2009 Michael Ledford. All rights reserved.
//

#import "S3CopyObjectOperation.h"

#import "S3ConnectionInfo.h"
#import "S3Bucket.h"
#import "S3Object.h"
#import "S3Extensions.h"

static NSString *S3OperationInfoCopyObjectOperationSourceObjectKey = @"S3OperationInfoCopyObjectOperationSourceObjectKey";
static NSString *S3OperationInfoCopyObjectOperationDestinationObjectKey = @"S3OperationInfoCopyObjectOperationDestinationObjectKey";

@implementation S3CopyObjectOperation

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c from:(S3Object *)source to:(S3Object *)destination
{
    NSMutableDictionary *theOperationInfo = [[NSMutableDictionary alloc] init];
    if (source) {
        [theOperationInfo setObject:source forKey:S3OperationInfoCopyObjectOperationSourceObjectKey];
    }
    if (destination) {
        [theOperationInfo setObject:destination forKey:S3OperationInfoCopyObjectOperationDestinationObjectKey];
    }
    
    self = [super initWithConnectionInfo:c operationInfo:theOperationInfo];
    
    [theOperationInfo release];
    
    if (self != nil) {
        
    }
    
	return self;
}

- (S3Object *)sourceObject
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoCopyObjectOperationSourceObjectKey];
}

- (S3Object *)destinationObject
{
    NSDictionary *theOperationInfo = [self operationInfo];
    return [theOperationInfo objectForKey:S3OperationInfoCopyObjectOperationDestinationObjectKey];
}

- (NSString *)kind
{
	return @"Object copy";
}

- (NSString *)requestHTTPVerb
{
    return @"PUT";
}

- (NSDictionary *)additionalHTTPRequestHeaders
{
    S3Object *sourceObject = [self sourceObject];
    S3Object *destinationObject = [self destinationObject];
    
    NSDictionary *destinationUserMetadata = [destinationObject userDefinedMetadata];
    NSMutableDictionary *additionalMetadata = [NSMutableDictionary dictionary];
    
    if ([destinationUserMetadata count]) {
        [additionalMetadata setObject:@"REPLACE" forKey:@"x-amz-metadata-directive"];
        [additionalMetadata addEntriesFromDictionary:[destinationObject metadata]];
    }
    
    NSString *copySource = [NSString stringWithFormat:@"/%@/%@", [[sourceObject bucket] name], [sourceObject key]];
    NSString *copySourceURLEncoded = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)copySource, NULL, (CFStringRef)@"[]#%?,$+=&@:;()'*!", kCFStringEncodingUTF8) autorelease];
    [additionalMetadata setObject:copySourceURLEncoded forKey:@"x-amz-copy-source"];
    
    return additionalMetadata;
}

- (BOOL)virtuallyHostedCapable
{
	return [[[self destinationObject] bucket] virtuallyHostedCapable];
}

- (NSString *)bucketName
{
    S3Object *destinationObject = [self destinationObject];
    
    return [[destinationObject bucket] name];
}

- (NSString *)key
{
    S3Object *destinationObject = [self destinationObject];
    
    return [destinationObject key];
}

- (BOOL)didInterpretStateForStreamHavingEndEncountered:(S3OperationState *)theState
{
    if ([[self responseStatusCode] isEqual:[NSNumber numberWithInt:200]]) {
        NSError *aError = nil;
        NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:[self responseData] options:NSXMLDocumentTidyXML error:&aError] autorelease];
        NSXMLElement *e = [d rootElement];
        if ([[e localName] isEqualToString:@"Error"]) {
            *theState = S3OperationError;
            return YES;
        }
    }
    
    return NO;
}
@end
