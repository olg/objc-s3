//
//  S3BucketDeleteOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3NSURLConnectionOperation.h"
#import "S3Connection.h"


@interface S3BucketDeleteOperation : S3NSURLConnectionOperation

+ (S3BucketDeleteOperation *)bucketDeletionWithConnection:(S3Connection *)c bucket:(S3Bucket *)b;

@end
