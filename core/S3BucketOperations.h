//
//  S3BucketListOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/1/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"

@class S3Owner;
@class S3Bucket;
@class S3Connection;

@interface S3BucketListOperation : S3NSURLConnectionOperation 

+(S3BucketListOperation*)bucketListOperationWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d;

-(NSMutableArray*)bucketList;
-(S3Owner*)owner;

@end

@interface S3BucketDeleteOperation : S3NSURLConnectionOperation

+(S3BucketDeleteOperation*)bucketDeletionWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b;

@end

@interface S3BucketAddOperation : S3NSURLConnectionOperation

+(S3BucketAddOperation*)bucketAddWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d name:(NSString*)name;

@end
