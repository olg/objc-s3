//
//  S3Connection.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/2/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3BucketOperations.h"

#define DEFAULT_HOST @"s3.amazonaws.com"
#define READ_TIMEOUT 30

@interface S3Connection : NSObject {
	NSString* _host;
	NSString* _accessKeyID;
	NSString* _secretAccessKey;
	
	NSMutableArray* _operations;
}

- (NSString *)accessKeyID;
- (void)setAccessKeyID:(NSString *)anAccessKeyID;
- (NSString *)secretAccessKey;
- (void)setSecretAccessKey:(NSString *)aSecretAccessKey;

- (NSMutableURLRequest*)makeRequestForMethod:(NSString*)method;
- (NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource;
- (NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource subResource:(NSString*)s;
- (NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource subResource:(NSString*)s  headers:(NSDictionary*)d;
- (NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource headers:(NSDictionary*)d;

- (NSString*)urlForBucket:(NSString*)b resource:(NSString*)r qualifier:(NSString*)q;

@end
