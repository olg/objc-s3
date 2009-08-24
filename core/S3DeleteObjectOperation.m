//
//  S3DeleteObjectOperation.m
//  S3-Objc
//
//  Created by Michael Ledford on 11/26/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3DeleteObjectOperation.h"

#import "S3ConnectionInfo.h"
#import "S3Bucket.h"
#import "S3Object.h"

@interface S3DeleteObjectOperation ()

@property(readwrite, retain) S3Object *object;

@end

@implementation S3DeleteObjectOperation

@synthesize object = _object;

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o
{
    self = [super initWithConnectionInfo:c];
    
    if (self != nil) {
        [self setObject:o];
    }
    
    return self;
}

- (NSString *)requestHTTPVerb
{
    return @"DELETE";
}

- (NSString *)bucketName
{
    return [[[self object] bucket] name];
}

- (NSString *)key
{
    return [[self object] key];
}

- (NSString *)kind
{
	return @"Object deletion";
}


@end
