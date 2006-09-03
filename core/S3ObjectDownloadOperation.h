//
//  S3ObjectDownloadOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"

@class S3Owner;
@class S3Object;
@class S3Bucket;
@class S3Connection;


/* The S3_DOWNLOADS_NSURLCONNECTION define controls if object download should be based on NSURLConnection (like in previous versions)
   or on NSURLDownload, which avoids keeping everything in a mutable data before saving (and also improves experience by 
   asking first the file destination, and track download progress in status).

   NSURLConnection-based object download operation will be removed in a future version.
*/

//#define S3_DOWNLOADS_NSURLCONNECTION

#ifndef S3_DOWNLOADS_NSURLCONNECTION

@interface S3ObjectDownloadOperation : S3Operation 
{
	long long _size;
	long long _received;
	int _percent;
	NSHTTPURLResponse* _response;
	NSURLRequest* _request;
	NSURLDownload* _connection;
}

+(S3ObjectDownloadOperation*)objectDownloadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b object:(S3Object*)o toPath:(NSString*)path;

@end

#else

@interface S3ObjectDownloadOperation : S3NSURLConnectionOperation 
{
	S3Object* _object;
}

+(S3ObjectDownloadOperation*)objectDownloadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b object:(S3Object*)o;
-(NSData*)data;

- (S3Object *)object;
- (void)setObject:(S3Object *)anObject;

@end

#endif
