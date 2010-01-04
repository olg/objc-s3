//
//  S3AddBucketOperation.h
//  S3-Objc
//
//  Created by Michael Ledford on 11/20/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h"

@class AWSRegion;
@class S3Bucket;

@interface S3AddBucketOperation : S3Operation {
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci bucket:(S3Bucket *)b region:(AWSRegion *)r;
- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci bucket:(S3Bucket *)b;

@property(readonly, nonatomic, copy) S3Bucket *bucket;
@property(readonly, nonatomic, copy) AWSRegion *region;

@end
