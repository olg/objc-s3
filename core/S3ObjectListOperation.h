//
//  S3ObjectListOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3ListOperation.h"
#import "S3Connection.h"
#import "S3Bucket.h"

@interface S3ObjectListOperation : S3ListOperation {
    S3Bucket *_bucket;
    S3Connection *_s3connection;
}

+ (S3ObjectListOperation *)objectListWithConnection:(S3Connection *)c bucket:(S3Bucket *)b;
+ (S3ObjectListOperation *)objectListWithConnection:(S3Connection *)c bucket:(S3Bucket *)b marker:(NSString *)marker;

- (NSMutableArray *)objects;
- (NSMutableDictionary *)metadata;

- (S3Connection *)connection;
- (void)setConnection:(S3Connection *)aConnection;

- (S3ObjectListOperation *)operationForNextChunk;

@end
