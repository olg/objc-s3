//
//  S3Owner.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Owner.h"

@interface S3Owner ()

@property(readwrite, copy) NSString *ID;
@property(readwrite, copy) NSString *displayName;

@end

@implementation S3Owner

@dynamic ID;
@synthesize displayName = _displayName;


- (id)initWithID:(NSString *)name displayName:(NSString *)date
{
	self = [super init];
    
    if (self != nil) {
        [self setID:name];
        [self setDisplayName:date];        
    }
    
	return self;
}

- (void)dealloc
{
	[_id release];
	[_displayName release];
	[super dealloc];
}

- (NSString *)ID
{
    return _id;
}

- (void)setID:(NSString *)anId
{
    NSString *newId = [anId copy];
    [_id release];
    _id = newId;
}

@end
