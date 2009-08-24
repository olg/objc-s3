//
//  S3AddBucketOperation.h
//  S3-Objc
//
//  Created by Michael Ledford on 11/20/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h"

@class S3Bucket;

@interface S3AddBucketOperation : S3Operation {
    S3Bucket *_bucket;
    NSString *_location;
    NSString *_locationConstraint;
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci bucket:(S3Bucket *)b location:(NSString *)l;
- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci bucket:(S3Bucket *)b;

@property(readonly, retain) S3Bucket *bucket;
@property(readonly, copy) NSString *location;

- (NSString *)kind;

@end
