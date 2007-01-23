//
//  S3Connection.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/2/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Bucket.h"

#define DEFAULT_HOST @"s3.amazonaws.com"
#define DEFAULT_PORT 80
#define DEFAULT_PROTOCOL @"http"

#define READ_TIMEOUT 30
#define XAMZACL @"x-amz-acl"

@interface S3Connection : NSObject {
    BOOL _secure;
	int _port;
	NSString* _host;
    
    NSString* _accessKeyID;
	NSString* _secretAccessKey;
	
	NSMutableArray* _operations;
}

- (NSString *)accessKeyID;
- (void)setAccessKeyID:(NSString *)anAccessKeyID;
- (NSString *)secretAccessKey;
- (void)setSecretAccessKey:(NSString *)aSecretAccessKey;

- (BOOL)isReady;

-(void)trySetupSecretAccessKeyFromKeychain;
-(void)storeSecretAccessKeyInKeychain;

- (NSMutableURLRequest*)makeRequestForMethod:(NSString*)method;
- (NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource;
- (NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource headers:(NSDictionary*)d;

- (NSURL*)urlForResource:(NSString*)resource;
- (NSString*)resourceForBucket:(S3Bucket*)bucket key:(NSString*)key;
- (NSString*)resourceForBucket:(S3Bucket*)bucket key:(NSString*)key;
- (NSString*)resourceForBucket:(S3Bucket*)bucket parameters:(NSString*)parameters;
- (NSString*)resourceForBucket:(S3Bucket*)bucket key:(NSString*)key parameters:(NSString*)parameters;

- (CFHTTPMessageRef)createCFRequestForMethod:(NSString*)method withResource:(NSString*)resource headers:(NSDictionary*)d;

@end
