//
//  S3Connection.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/2/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Connection.h"
#import "S3Extensions.h"
#import "S3ObjectListController.h"

#import <Security/Security.h>
// C-string, as it is only used in Keychain Services
#define S3_BROWSER_KEYCHAIN_SERVICE "S3 Browser"



@implementation S3Connection

-(id)init
{
	[super init];
	_host = DEFAULT_HOST;
	_port = DEFAULT_PORT;
    _secure = NO; 
	_operations = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
    [self setAccessKeyID:nil];
    [self setSecretAccessKey:nil];
    [_host release];
    [_operations release];
	[super dealloc];
}

-(BOOL)isReady
{
    return (_accessKeyID!=nil)&&(_secretAccessKey!=nil);
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
#pragma mark Keychain integration

- (NSString*)getS3KeyFromKeychainForUser:(NSString *)username
{
	void *passwordData = nil; // will be allocated and filled in by SecKeychainFindGenericPassword
	UInt32 passwordLength = 0;
    
	NSString* password = nil;
	const char *user = [username UTF8String]; 
    
	OSStatus status;
	status = SecKeychainFindGenericPassword (NULL, // default keychain
                                             strlen(S3_BROWSER_KEYCHAIN_SERVICE), S3_BROWSER_KEYCHAIN_SERVICE,
                                             strlen(user), user,
                                             &passwordLength, &passwordData,
                                             nil);
	if (status==noErr)
		password = [[[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding] autorelease];
	SecKeychainItemFreeContent(NULL,passwordData);	
	
	return password;
}


- (BOOL)setS3KeyToKeychainForUser:(NSString *)username password:(NSString*)password
{
	const char *user = [username UTF8String]; 
	const char *pass = [password UTF8String]; 
	
	OSStatus status;
	status = SecKeychainAddGenericPassword(NULL, // default keychain
                                           strlen(S3_BROWSER_KEYCHAIN_SERVICE),S3_BROWSER_KEYCHAIN_SERVICE,
                                           strlen(user), user,
                                           strlen(pass), pass,
                                           nil);
	return (status==noErr);
}

-(void)trySetupSecretAccessKeyFromKeychain
{
	NSString* password = [self getS3KeyFromKeychainForUser:[self accessKeyID]];
	if (password!=nil)
		[self setSecretAccessKey:password];
}

-(void)storeSecretAccessKeyInKeychain
{
    [self setS3KeyToKeychainForUser:[self accessKeyID] password:[self secretAccessKey]];
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
	NSString* ct = [headers objectForKey:@"Content-Type"];
	if (ct!=nil)
		contentType = ct;
	
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

    if ([[[conn URL] query] hasPrefix:@"acl"])
        [buf appendFormat:@"%@?acl",[[[conn URL] path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    else if ([[[conn URL] query] hasPrefix:@"torrent"])
        [buf appendFormat:@"%@?torrent",[[[conn URL] path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    else
        [buf appendFormat:@"%@",[[[conn URL] path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

	NSString* auth = [[[buf dataUsingEncoding:NSUTF8StringEncoding] sha1HMacWithKey:_secretAccessKey] encodeBase64];
	[conn addValue:[NSString stringWithFormat:@"AWS %@:%@",_accessKeyID,auth] forHTTPHeaderField:@"Authorization"];
}

-(NSMutableURLRequest*)makeRequestForMethod:(NSString*)method
{
	return [self makeRequestForMethod:method withResource:nil headers:nil];
}

-(NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource
{
	return [self makeRequestForMethod:method withResource:resource headers:nil];
}

-(NSMutableURLRequest*)makeRequestForMethod:(NSString*)method withResource:(NSString*)resource headers:(NSDictionary*)d
{
    NSURL* rootURL = [self urlForResource:resource];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:rootURL];
	[request setHTTPMethod:method];
	[request setTimeoutInterval:READ_TIMEOUT];
	[self addAuthorization:request method:method data:nil headers:d];	
	[request setHTTPMethod:method];

	return request;
}


-(void)addAuthorizationToCF:(CFHTTPMessageRef)conn method:(NSString*)method data:(id)data headers:(NSDictionary*)headers url:(NSURL*)url
{															
	NSString* contentType = @"";
	// for additional security, include a content-md5 tag with any
	// query that is supplying data to S3
	NSString* contentMD5 = @"";
	if(data != nil) {
		NSString* contentMD5 = [[data md5Digest] encodeBase64];
		CFHTTPMessageSetHeaderFieldValue(conn, CFSTR("Content-MD5"), (CFStringRef)contentMD5);
	}
	NSString* ct = [headers objectForKey:@"Content-Type"];
	if (ct!=nil)
		contentType = ct;

	NSString* k;
	NSEnumerator* e;
	e = [headers keyEnumerator];
	while (k = [e nextObject])
	{
		id o = [headers objectForKey:k];
		CFHTTPMessageSetHeaderFieldValue(conn, (CFStringRef)k, (CFStringRef)o);
	}
	
	NSCalendarDate * date = [NSCalendarDate calendarDate];
	[date setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSString* dateString = [date descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"];
	CFHTTPMessageSetHeaderFieldValue(conn, CFSTR("Date"), (CFStringRef)dateString);

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
	[buf appendFormat:@"%@",[[url path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

	
	NSString* auth = [[[buf dataUsingEncoding:NSUTF8StringEncoding] sha1HMacWithKey:_secretAccessKey] encodeBase64];
	CFHTTPMessageSetHeaderFieldValue(conn, CFSTR("Authorization"), (CFStringRef)[NSString stringWithFormat:@"AWS %@:%@",_accessKeyID,auth]);
}

-(CFHTTPMessageRef)createCFRequestForMethod:(NSString*)method withResource:(NSString*)resource headers:(NSDictionary*)d
{
	NSURL* rootURL = [self urlForResource:resource];
	
	CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)method, (CFURLRef)rootURL, kCFHTTPVersion1_1);
	[self addAuthorizationToCF:request method:method data:nil headers:d url:rootURL];	
	
	return request;
}

-(NSString*)resourceForBucket:(S3Bucket*)bucket key:(NSString*)key
{
    return [self resourceForBucket:bucket key:key parameters:nil];
}

-(NSString*)resourceForBucket:(S3Bucket*)bucket parameters:(NSString*)parameters
{
    return [self resourceForBucket:bucket key:nil parameters:parameters];
}

-(NSString*)resourceForBucket:(S3Bucket*)bucket key:(NSString*)key parameters:(NSString*)parameters
{
    if (bucket==nil)
        bucket=@"";
    
    if ((key==nil)||([[key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]))
        if (parameters!=nil)
            return [NSString stringWithFormat:@"%@%@",[bucket name],parameters];
        else
            return [bucket name];

    if (parameters!=nil)
        return [NSString stringWithFormat:@"%@/%@%@",[bucket name],[key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],parameters];
    else
        return [NSString stringWithFormat:@"%@/%@",[bucket name],[key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

-(NSURL*)urlForResource:(NSString*)resource
{
    NSMutableString* url;
    
    if (resource==nil)
        resource=@"";

    if (_secure)
        url = [NSMutableString stringWithString:@"https://"];
    else
        url = [NSMutableString stringWithString:@"http://"];

    if (_port!=80)
        [url appendFormat:@"%@:%d/%@",_host,_port,resource];
    else
        [url appendFormat:@"%@/%@",_host,resource];

	return [NSURL URLWithString:url];
}

@end
