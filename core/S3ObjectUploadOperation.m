//
//  S3ObjectUploadOperation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/16/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ObjectUploadOperation.h"

#define UPLOAD_HTTP_METHOD @"PUT"

@implementation S3ObjectUploadOperation

-(NSString*)kind
{
	return @"Object upload";
}

+(S3ObjectUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b data:(NSDictionary*)data acl:(NSString*)acl
{
    NSString* mimeType = [data objectForKey:FILEDATA_TYPE];
    NSData* content = [NSData dataWithContentsOfFile:[data objectForKey:FILEDATA_PATH]];
    
	NSDictionary* headers;
	if ((mimeType==nil) || ([[mimeType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]))
		headers = [NSDictionary dictionaryWithObject:acl forKey:XAMZACL];
	else
		headers = [NSDictionary dictionaryWithObjectsAndKeys:acl,XAMZACL,mimeType,@"Content-Type",nil];
		
	NSMutableURLRequest* rootConn = [c makeRequestForMethod:UPLOAD_HTTP_METHOD withResource:[c resourceForBucket:b key:[data objectForKey:FILEDATA_KEY]] headers:headers];
	[rootConn setHTTPBody:content];
	S3ObjectUploadOperation* op = [[[S3ObjectUploadOperation alloc] initWithRequest:rootConn delegate:d] autorelease];
	return op;
}

@end

