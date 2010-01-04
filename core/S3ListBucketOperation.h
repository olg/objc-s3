//
//  S3ListBucketOperation.h
//  S3-Objc
//
//  Created by Michael Ledford on 8/24/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h"

@class S3Owner;

@interface S3ListBucketOperation : S3Operation {
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)connectionInfo;

- (NSArray *)bucketList;
- (S3Owner *)owner;

@end
