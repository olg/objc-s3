//
//  S3ObjectStreamedUploadOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"
#import "S3Connection.h"

@class S3TransferRateCalculator;

@interface S3ObjectStreamedUploadOperation : S3Operation 
{
	NSInputStream *_istream;
	NSOutputStream *_ostream;
	NSInputStream *_fstream;
    NSMutableData *_ibuffer;
    NSMutableData *_obuffer;
	CFDataRef _headerData;
	CFHTTPMessageRef _response;
	CFHTTPMessageRef _request;
	NSString *_path;
	S3TransferRateCalculator *_rateCalculator;
}

+ (S3ObjectStreamedUploadOperation *)objectUploadWithConnection:(S3Connection *)c bucket:(S3Bucket *)b data:(NSDictionary *)data acl:(NSString *)acl;
- (NSString *)headerFieldValue:(NSString *)headerField;
- (NSDictionary *)headerFieldsAndValues;
- (NSArray *)headerFields;
- (NSString *)path;

@end