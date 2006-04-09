//
//  S3Connection.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/2/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Connection.h"
#import "S3Extensions.h"
#import "S3BucketContentController.h"


@implementation S3Connection

-(id)init
{
	[super init];
	_host = DEFAULT_HOST;
	_operations = [[NSMutableArray alloc] init];
	return self;
}

- (NSString *)accessKeyID
{
    return _accessKeyID; 
}

- (void)setAccessKeyID:(NSString *)anAccessKeyID
{
    [_accessKeyID release];
    _accessKeyID = [anAccessKeyID retain];
}

- (NSString *)secretAccessKey
{
    return _secretAccessKey; 
}

- (void)setSecretAccessKey:(NSString *)aSecretAccessKey
{
    [_secretAccessKey release];
    _secretAccessKey = [aSecretAccessKey retain];
}

#pragma mark -
#pragma mark URL Construction

#define AMZ_PREFIX @"x-amz"

-(void)addAuthorization:(NSMutableURLRequest*)conn method:(NSString*)method data:(id)data headers:(NSDictionary*)headers
{															
	NSString* contentType = @"";
	// for additional security, include a content-md5 tag with any
	// query that is supplying data to S3
	NSString* contentMD5 = @"";
	if(data != nil) {
		NSString* contentMD5 = [[data md5Digest] encodeBase64];
		[conn addValue:contentMD5 forHTTPHeaderField:@"Content-MD5"];
	}
	NSString* k;
	NSEnumerator* e;
	e = [headers keyEnumerator];
	while (k = [e nextObject])
	{
		id o = [headers objectForKey:k];
		[conn addValue:o forHTTPHeaderField:k];
	}
	
	NSCalendarDate * date = [NSCalendarDate calendarDate];
	[date setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSString* dateString = [date descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"];
	[conn addValue:dateString forHTTPHeaderField:@"Date"];
	
	// S3 authentication works as a SHA1 hash of the following information
	// in this precise order
	NSMutableString* buf = [NSMutableString string];
	[buf appendFormat:@"%@\n",method];
	[buf appendFormat:@"%@\n",contentMD5];
	[buf appendFormat:@"%@\n",contentType];
	[buf appendFormat:@"%@\n",dateString];
	
	e = [[[headers allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
	while (k = [e nextObject])
	{
		id o = [headers objectForKey:k];
		if ([k hasPrefix:AMZ_PREFIX])
			[buf appendFormat:@"%@:%@\n",k,o];
	}
	[buf appendFormat:@"%@",[[[conn URL] path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

	
	NSString* auth = [[[buf dataUsingEncoding:NSUTF8StringEncoding] sha1HMacWithKey:_secretAccessKey] encodeBase64];
	[conn addValue:[NSString stringWithFormat:@"AWS %@:%@",_accessKeyID,auth] forHTTPHeaderField:@"Authorization"];
	
}

-(NSString*)urlForBucket:(NSString*)b resource:(NSString*)r qualifier:(NSString*)q
{
	if (q==nil)
		return [NSString stringWithFormat:@"http://%@/%@/%@?q",_host,b,r];
	else 
		return [NSString stringWithFormat:@"http://%@/%@/%@/%@",_host,b,r];
}

-(NSMutableURLRequest*)makeRequestForMethod:(NSString*)method
{
	return [self makeRequestForMethod:method withResource:nil headers:nil];
}

-(NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource
{
	return [self makeRequestForMethod:method withResource:resource headers:nil];
}

-(NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource subResource:(NSString*)s
{
	return [self makeRequestForMethod:method withResource:resource subResource:s headers:nil];
}

-(NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource subResource:(NSString*)s headers:(NSDictionary*)d
{
	return [self makeRequestForMethod:method withResource:[resource stringByAppendingPathComponent:[s stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] headers:d];
}

-(NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource headers:(NSDictionary*)d
{
	NSString* url;
	if (resource==nil)
		url = [NSString stringWithFormat:@"http://%@/",_host];
	else 
		url = [NSString stringWithFormat:@"http://%@/%@",_host,resource];

	NSURL* rootURL = [NSURL URLWithString:url];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:rootURL];
	[request setHTTPMethod:method];
	[request setTimeoutInterval:READ_TIMEOUT];
	[self addAuthorization:request method:method data:nil headers:d];	
	[request setHTTPMethod:method];

	return request;
}


@end
