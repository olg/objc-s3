//
//  S3Bucket.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Bucket.h"
#import "S3Extensions.h"

@interface S3Bucket (PrivateAPI)
- (void)setCreationDate:(NSDate *)aCreationDate;
- (void)setName:(NSString *)aName;
@end

@implementation S3Bucket

- (id)initWithName:(NSString *)name creationDate:(NSDate *)date
{
	[super init];
	[self setName:name];
	[self setCreationDate:date];
	return self;
}

+ (S3Bucket *)bucketWithXMLNode:(NSXMLElement *)element
{
	NSString *name = nil;
	NSCalendarDate *date = nil;

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

- (unsigned)hash
{
    return ([_creationDate hash] ^ [_name hash]);
}

- (BOOL)isEqual:(id)obj
{
    if ([obj isKindOfClass:[self class]] == YES) {
        // Checking on both the creationDate and name is probably overkill
        // since bucket names are globally unique in S3. However, the object
        // could have been created without one or the other (or both) so
        // we're going to enforce equality using both.
        if (_creationDate != nil && _name != nil) {
            if ([_creationDate isEqualToDate:[obj creationDate]] && [_name isEqualToString:[obj name]]) {
                return YES;
            }
        } else if (_name != nil) {
            if ([_name isEqualToString:[obj name]] && (_creationDate == [obj creationDate])) {
                return YES;
            }
        } else if (_creationDate != nil) {
            if ([_creationDate isEqualToDate:[obj creationDate]] && (_name == [obj name])) {
                return YES;
            }
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
