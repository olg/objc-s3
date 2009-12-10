//
//  S3ListObjectOperation.h
//  S3-Objc
//
//  Created by Michael Ledford on 11/19/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h"

@interface S3ListObjectOperation : S3Operation {
    S3Bucket *_bucket;
    NSString *_marker;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)bucket marker:(NSString *)marker;
- (id)initWithConnectionInfo:(S3ConnectionInfo *)theConnectionInfo bucket:(S3Bucket *)bucket;

@property(readonly, retain) S3Bucket *bucket;
@property(readonly, copy) NSString *marker;

- (NSArray *)objects;
- (NSMutableDictionary *)metadata;
- (S3ListObjectOperation *)operationForNextChunk;

@end
