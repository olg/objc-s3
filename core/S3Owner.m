//
//  S3Owner.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Owner.h"


@implementation S3Owner

-(id)initWithID:(NSString*)name displayName:(NSString*)date
{
	[super init];
	[self setID:name];
	[self setDisplayName:date];
	return self;
}

- (NSString *)ID
{
    return _id; 
}

- (void)setID:(NSString *)anId
{
    [_id release];
    _id = [anId retain];
}


- (NSString *)displayName
{
    return _displayName; 
}
- (void)setDisplayName:(NSString *)aDisplayName
{
    [_displayName release];
    _displayName = [aDisplayName retain];
}

+(S3Owner*)ownerWithXMLNode:(NSXMLElement*)element
{
	NSString* name = nil;
	NSString* ownerID = nil;
	NSArray* a;
	
	a = [element elementsForName:@"ID"];
	if ([a count]==1)
		ownerID = [[a objectAtIndex:0] stringValue];
	a = [element elementsForName:@"DisplayName"];
	if ([a count]==1)
		name = [[a objectAtIndex:0] stringValue];
	
	if (name!=nil)
		return [[[S3Owner alloc] initWithID:ownerID displayName:name] autorelease];
	else
		return nil;
}

@end
