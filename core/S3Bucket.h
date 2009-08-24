//
//  S3Bucket.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* Amazon Doc:
Objects are stored in buckets. The bucket provides a unique namespace for management of objects 
contained in the bucket. Each bucket you create is owned by you for purposes of billing, and you will be 
charged storage fees for all objects stored in the bucket and bandwidth fees for all data read from and 
written to the bucket. There is no limit to the number of objects that one bucket can hold. Since the 
namespace for bucket names is global, each developer is limited to owning 100 buckets at a time. 
*/

@class S3ListBucketOperation;

@interface S3Bucket : NSObject <NSCopying, NSMutableCopying> {
	NSString *_name;
	NSDate *_creationDate;
}

- (id)initWithName:(NSString *)name creationDate:(NSDate *)date;
- (id)initWithName:(NSString *)name;

- (NSDate *)creationDate;
- (NSString *)name;

@end
