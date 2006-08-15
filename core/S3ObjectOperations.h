//
//  S3ObjectOperations.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/9/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"

@class S3Owner;
@class S3Object;
@class S3Bucket;
@class S3Connection;



@interface S3ObjectUploadOperation : S3NSURLConnectionOperation

+(S3ObjectUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b key:(NSString*)k data:(NSData*)n acl:(NSString*)acl;

@end


@interface S3ObjectDeleteOperation : S3NSURLConnectionOperation

+(S3ObjectDeleteOperation*)objectDeletionWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b object:(S3Object*)o;

@end

// Bucket operations

@interface S3ObjectListOperation : S3NSURLConnectionOperation {
	S3Bucket* _bucket;
}

+(S3ObjectListOperation*)objectListWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b;

-(NSMutableArray*)objects;
-(NSMutableDictionary*)metadata;

@end