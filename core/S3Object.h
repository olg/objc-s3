//
//  S3Object.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* Amazon Doc:
Objects are the fundamental entities stored in Amazon S3. Objects are composed of object data and 
metadata. The data portion is opaque to Amazon S3. The metadata is a set of name-value pairs that 
describe the object. These include some default metadata such as the date last modified, and standard 
HTTP metadata such as Content-Type. The developer may also specify custom metadata at the time the 
Object is stored. 
*/

// TODO: Keys for default metadata

@class S3Bucket;

#define S3_USER_PREFIX @"x-amz-meta-"
#define S3_ERROR_MARKER @"x-amz-missing-meta"

@interface S3Object : NSObject {
	NSData* _data;
	NSMutableDictionary* _metadata;
	S3Bucket* _bucket;
}

+ (S3Object*)objectWithXMLNode:(NSXMLElement*)element;
- (id)initWithData:(NSData*)d metaData:(NSDictionary*)d;

- (NSString*)key;

- (NSData *)data;
- (void)setData:(NSData *)aData;
- (NSDictionary *)metadata;
- (void)setMetadata:(NSDictionary *)aMetadata;

- (S3Bucket *)bucket;
- (void)setBucket:(S3Bucket *)aBucket;

@end
