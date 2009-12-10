//
//  S3Object.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Re-imagined by Michael Ledford on 12/7/08.
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

@class S3Bucket;
@class S3Owner;
@class S3ListObjectOperation;

// Keys for default metadata

extern NSString *S3UserDefinedObjectMetadataMissingKey;

extern NSString *S3ObjectFilePathDataSourceKey;
extern NSString *S3ObjectNSDataSourceKey;

extern NSString *S3ObjectMetadataACLKey;
extern NSString *S3ObjectMetadataContentMD5Key;
extern NSString *S3ObjectMetadataContentTypeKey;
extern NSString *S3ObjectMetadataContentLengthKey;
extern NSString *S3ObjectMetadataETagKey;
extern NSString *S3ObjectMetadataLastModifiedKey;
extern NSString *S3ObjectMetadataOwnerKey;
extern NSString *S3ObjectMetadataStorageClassKey;

@interface S3Object : NSObject {
    NSString *_key;
	S3Bucket *_bucket;
	NSDictionary *_metadata;
	NSDictionary *_dataSourceInfo;
}

// Initializes an S3Object with the bucket it is contained in, the key that identifies it in that bucket, user 
// defined metadata and metadata that is stored along with the object and a data source that provides the data
// for the object. User defined metadata is transformed internally to a specially formed metadata-key and stored
// with the metadata-key accepted by Amazon's S3 service.
- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd metadata:(NSDictionary *)md dataSourceInfo:(NSDictionary *)info;

// Initializes an S3Object with the bucket it is contained in, the key that identifies it in that bucket,
// user defined metadata and metadata that is stored along with the object. User defined metadata is 
// transformed internally to a specially formed metadata-key and stored with the metadata-key accepted by
// Amazon's S3 service. If the specially formed metadata also exists in metadata then metadata will win.
- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd metadata:(NSDictionary *)md;

// Initializes an S3Object with the bucket it is contained in, the key that identifies it in that bucket and
// user defined metadata that is stored along with the object. User defined metadata is transformed internally
// to a specially formed metadata-key and stored with the metadata-key accepted by Amazon's S3 service.
- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key userDefinedMetadata:(NSDictionary *)udmd;

// Initializes an S3Object with the bucket it is contained in and the key that identifies it in that bucket.
- (id)initWithBucket:(S3Bucket *)bucket key:(NSString *)key;

@property(readonly, retain) S3Bucket *bucket;
@property(readonly, copy) NSString *key;
@property(readonly, copy) NSDictionary *dataSourceInfo;
@property(readonly, copy) NSDictionary *metadata;
@property(readonly, copy) NSDictionary *userDefinedMetadata;

// Exposes standard Amazon metadata in a KVO complient way.
@property(readonly, copy) NSString *acl;
@property(readonly, copy) NSString *contentMD5;
@property(readonly, copy) NSString *contentType;
@property(readonly, copy) NSString *contentLength;
@property(readonly, copy) NSString *etag;
@property(readonly, copy) NSString *lastModified;
@property(readonly, copy) S3Owner *owner;
@property(readonly, copy) NSString *storageClass;
@property(readonly) BOOL missingMetadata;

@end
