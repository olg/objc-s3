//
//  S3ObjectStreamedUploadOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"
#import "S3Connection.h"

@interface S3ObjectStreamedUploadOperation : S3Operation 
{
	long long _size;
	long long _sent;
	int _percent;
	
	NSInputStream* _istream;
	NSOutputStream* _ostream;
	NSInputStream* _fstream;
    NSMutableData* _ibuffer;
    NSMutableData* _obuffer;
	CFDataRef _headerData;
	CFHTTPMessageRef _response;
	CFHTTPMessageRef _request;
	NSString* _path;
}

+ (S3ObjectStreamedUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b data:(NSDictionary*)data acl:(NSString*)acl;

@end