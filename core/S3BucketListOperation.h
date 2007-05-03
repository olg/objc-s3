//
//  S3BucketListOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3ListOperation.h"
#import "S3Connection.h"
#import "S3Owner.h"

@interface S3BucketListOperation : S3ListOperation 

+ (S3BucketListOperation *)bucketListOperationWithConnection:(S3Connection *)c;

-(NSMutableArray *)bucketList;
-(S3Owner *)owner;

@end
