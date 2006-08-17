//
//  S3ObjectUploadOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/16/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"
#import "S3Connection.h"

// #define S3_AVOID_STREAMED_UPLOAD

@interface S3ObjectUploadOperation : S3NSURLConnectionOperation 

+(S3ObjectUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k data:(NSData*)n acl:(NSString*)acl;

@end

@interface S3ObjectStreamedUploadOperation : S3Operation 
{
	long long _size;
	long long _sent;
	
	NSInputStream* istream;
	NSOutputStream* ostream;
	NSInputStream* fstream;
	CFDataRef _headerData;
	CFHTTPMessageRef _response;
    NSMutableData* ibuffer;
    NSMutableData* obuffer;
}

+ (S3ObjectStreamedUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k path:(NSString*)path acl:(NSString*)acl;

@end