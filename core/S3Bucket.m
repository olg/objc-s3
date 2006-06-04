//
//  S3Bucket.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Bucket.h"
#import "S3Extensions.h"


@implementation S3Bucket

-(id)initWithName:(NSString*)name creationDate:(NSDate*)date
{
	[super init];
	[self setName:name];
	[self setCreationDate:date];
	return self;
}

+(S3Bucket*)bucketWithXMLNode:(NSXMLElement*)element
{
	NSString* name = nil;
	NSCalendarDate* date = nil;

	name = [[element elementForName:@"Name"] stringValue];
	date = [[element elementForName:@"CreationDate"] dateValue];
						   
	if (name!=nil)
		return [[[S3Bucket alloc] initWithName:name creationDate:date] autorelease];
	else
		return nil;
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

@end
