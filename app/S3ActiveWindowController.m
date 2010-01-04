//
//  S3ActiveWindowController.m
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ActiveWindowController.h"

#import "S3ConnectionInfo.h"
#import "S3MutableConnectionInfo.h"
#import "S3ApplicationDelegate.h"
#import "S3Operation.h"
#import "S3OperationQueue.h"
#import "S3OperationLog.h"

@implementation S3ActiveWindowController

- (void)awakeFromNib
{
    _operations = [[NSMutableArray alloc] init];
    _redirectConnectionInfoMappings = [[NSMutableDictionary alloc] init];
}

#pragma mark -
#pragma mark S3OperationQueue Notifications

- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
{
    S3Operation *operation = [[notification userInfo] objectForKey:S3OperationObjectKey];
    unsigned index = [_operations indexOfObjectIdenticalTo:operation];
    if (index == NSNotFound) {
        return;
    }
        
    if ([operation state] == S3OperationCanceled || [operation state] == S3OperationRequiresRedirect || [operation state] == S3OperationDone) {
        [_operations removeObjectAtIndex:index];
        [[[NSApp delegate] operationLog] unlogOperation:operation];
    }
    
    if ([operation state] == S3OperationRequiresRedirect) {        
        NSData *operationResponseData = [operation responseData];
        NSError *error = nil;
        NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:operationResponseData options:NSXMLDocumentTidyXML error:&error] autorelease];
        if (error) {
            return;
        }
        
        NSArray *buckets = [[d rootElement] nodesForXPath:@"//Bucket" error:&error];
        if (error) {
            return;
        }
        NSString *bucketName = nil;
        if ([buckets count] == 1) {
            bucketName = [[buckets objectAtIndex:0] stringValue];
            bucketName = [NSString stringWithFormat:@"%@.", bucketName];
        }
        
        NSArray *endpoints = [[d rootElement] nodesForXPath:@"//Endpoint" error:&error];
        NSString *endpoint = nil;
        if ([endpoints count] == 1) {
            endpoint = [[endpoints objectAtIndex:0] stringValue];
        }
        
        if (bucketName && endpoint) {
            NSRange bucketNameInEndpointRange = [endpoint rangeOfString:bucketName];
            if (NSEqualRanges(bucketNameInEndpointRange, NSMakeRange(NSNotFound, 0))) {
                return;
            }
            NSString *pureEndpoint = [endpoint stringByReplacingCharactersInRange:bucketNameInEndpointRange withString:@""];
            NSDictionary *operationInfo = [[operation operationInfo] copy];
            S3ConnectionInfo *operationConnectionInfo = [operation connectionInfo];
            S3MutableConnectionInfo *redirectConnectionInfo = [operationConnectionInfo mutableCopy];
            [redirectConnectionInfo setHostEndpoint:pureEndpoint];
            [redirectConnectionInfo setDelegate:self];
            
            [_redirectConnectionInfoMappings setObject:operationConnectionInfo forKey:redirectConnectionInfo];
            
            S3Operation *replacementOperation = [[[operation class] alloc] initWithConnectionInfo:redirectConnectionInfo operationInfo:operationInfo];
            [redirectConnectionInfo release];
            [operationInfo release];
            
            [self addToCurrentOperations:replacementOperation];
            [replacementOperation release];
        }        
    }
    
    if ([_redirectConnectionInfoMappings objectForKey:[operation connectionInfo]]) {
        int activeConnectionInfos = 0;
        for (S3Operation *currentOperation in _operations) {
            if ([[currentOperation connectionInfo] isEqual:[operation connectionInfo]]) {
                activeConnectionInfos++;
            }
        }
        if (activeConnectionInfos == 1) {
            [_redirectConnectionInfoMappings removeObjectForKey:[operation connectionInfo]];            
        }
    }    
}

#pragma mark -

- (void)addToCurrentOperations:(S3Operation *)op
{
	if ([[[NSApp delegate] queue] addToCurrentOperations:op]) {
		[_operations addObject:op];
        [[[NSApp delegate] operationLog] logOperation:op];
    }
}

- (BOOL)hasActiveOperations
{
	return ([_operations count] > 0);
}

- (S3ConnectionInfo *)connectionInfo
{
    return _connectionInfo; 
}

- (void)setConnectionInfo:(S3ConnectionInfo *)aConnectionInfo
{
    [aConnectionInfo retain];
    [_connectionInfo release];
    _connectionInfo = aConnectionInfo;
}

#pragma mark -
#pragma mark S3ConnectionInfo Delegates

- (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo
{
    S3ConnectionInfo *originalConnectionInfo = [_redirectConnectionInfoMappings objectForKey:connectionInfo];
    id originalDelegate = [originalConnectionInfo delegate];
    if ([originalDelegate respondsToSelector:@selector(accessKeyForConnectionInfo:)]) {
        return [originalDelegate accessKeyForConnectionInfo:originalConnectionInfo];
    }
    return nil;
}

- (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo
{
    S3ConnectionInfo *originalConnectionInfo = [_redirectConnectionInfoMappings objectForKey:connectionInfo];
    id originalDelegate = [originalConnectionInfo delegate];
    if ([originalDelegate respondsToSelector:@selector(secretAccessKeyForConnectionInfo:)]) {
        return [originalDelegate secretAccessKeyForConnectionInfo:originalConnectionInfo];
    }
    return nil;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc
{
	[self setConnectionInfo:nil];
    [_operations release];
    [_redirectConnectionInfoMappings release];
	[super dealloc];
}

@end
