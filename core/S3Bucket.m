//
//  S3Bucket.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Bucket.h"
#import "S3Extensions.h"
#import "S3ListBucketOperation.h"

NSString *S3BucketUSWestLocationKey = @"us-west-1";
NSString *S3BucketEUIrelandLocationKey = @"EU";

@interface S3Bucket (S3BucketPrivateAPI)
- (void)setCreationDate:(NSDate *)aCreationDate;
- (void)setName:(NSString *)aName;
@end

@implementation S3Bucket

- (id)initWithName:(NSString *)name creationDate:(NSDate *)date
{
	self = [super init];

    if (self != nil) {
        if (name == nil) {
            [self release];
            return nil;
        }        
        [self setName:name];
        [self setCreationDate:date];
    }

	return self;
}

- (id)initWithName:(NSString *)name
{
    return [self initWithName:name creationDate:nil];
}

- (void)dealloc
{
    [_creationDate release];
    [_name release];
    [super dealloc];
}

- (NSDate *)creationDate
{
    return _creationDate; 
}

- (void)setCreationDate:(NSDate *)aCreationDate
{
    [_creationDate release];
    _creationDate = [aCreationDate retain];
}

- (NSString *)name
{
    return _name; 
}

- (void)setName:(NSString *)aName
{
    [_name release];
    _name = [aName retain];
}

- (unsigned)hash
{
    return [_name hash];
}

- (BOOL)isEqual:(id)obj
{
    if ([obj isKindOfClass:[self class]] == YES) {
        if ([[self name] isEqualToString:[obj name]]) {
            return YES;
        }
    }    
    return NO;
}

- (id)copyWithZone:(NSZone *)zone {
    return [self retain];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [self retain];
}
@end
