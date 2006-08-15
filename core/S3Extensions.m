//
//  S3Extensions.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/31/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Extensions.h"
#import <openssl/ssl.h>
#import <openssl/hmac.h>

@implementation NSString (Comfort)

- (long long)longLongValue {
	long long v;
	
	NSScanner* scanner = [[NSScanner alloc] initWithString:self];
	if(![scanner scanLongLong:&v])
		v = 0;
	
	[scanner release];	
	return v;
}

@end


@implementation NSMutableDictionary (Comfort)

-(void)safeSetObject:(id)o forKey:(NSString*)k
{
	if ((o==nil)||(k==nil))
		return;
	[self setObject:o forKey:k];
}

@end


@implementation NSXMLElement (Comfort)

-(NSXMLElement*)elementForName:(NSString*)n
{
	NSArray* a = [self elementsForName:n];
	if ([a count]>0)
		return [a objectAtIndex:0];
	else 
		return nil;
}

-(NSNumber*)longLongNumber
{
	return [NSNumber numberWithLongLong:[[self stringValue] longLongValue]];
}

-(NSNumber*)boolNumber
{
	// I don't trust the output format, the S3 doc sometimes mentions a "false;"
	if ([[self stringValue] rangeOfString:@"true" options:NSCaseInsensitiveSearch].location!=NSNotFound)
		return [NSNumber numberWithBool:TRUE];
	else
		return [NSNumber numberWithBool:FALSE];
}

-(NSCalendarDate*)dateValue
{
	return [NSCalendarDate dateWithString:[self stringValue] calendarFormat:@"%Y-%m-%dT%H:%M:%S.%FZ"];
}

@end


@implementation NSData (OpenSSLWrapper)

- (NSData *)md5Digest
{
	EVP_MD_CTX mdctx;
	unsigned char md_value[EVP_MAX_MD_SIZE];
	unsigned int md_len;
	EVP_DigestInit(&mdctx, EVP_md5());
	EVP_DigestUpdate(&mdctx, [self bytes], [self length]);
	EVP_DigestFinal(&mdctx, md_value, &md_len);
	return [NSData dataWithBytes:md_value length:md_len];
}

- (NSData *)sha1Digest
{
	EVP_MD_CTX mdctx;
	unsigned char md_value[EVP_MAX_MD_SIZE];
	unsigned int md_len;
	EVP_DigestInit(&mdctx, EVP_sha1());
	EVP_DigestUpdate(&mdctx, [self bytes], [self length]);
	EVP_DigestFinal(&mdctx, md_value, &md_len);
	return [NSData dataWithBytes:md_value length:md_len];
}

- (NSData *)sha1HMacWithKey:(NSString*)key
{
	HMAC_CTX mdctx;
	unsigned char md_value[EVP_MAX_MD_SIZE];
	unsigned int md_len;
	const char* k = [key cStringUsingEncoding:NSUTF8StringEncoding];
	const unsigned char *data = [self bytes];
	int len = [self length];
	
	HMAC_CTX_init(&mdctx);
	HMAC_Init(&mdctx,k,strlen(k),EVP_sha1());
	HMAC_Update(&mdctx,data, len);
	HMAC_Final(&mdctx, md_value, &md_len);
	HMAC_CTX_cleanup(&mdctx);
	return [NSData dataWithBytes:md_value length:md_len];
}
	
- (NSString*)encodeBase64
{
    return [self encodeBase64WithNewlines:NO];
}

- (NSString*) encodeBase64WithNewlines:(BOOL) encodeWithNewlines
{
    BIO * mem = BIO_new(BIO_s_mem());
	BIO * b64 = BIO_new(BIO_f_base64());
    if (!encodeWithNewlines)
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    mem = BIO_push(b64, mem);

	BIO_write(mem, [self bytes], [self length]);
    BIO_flush(mem);
		
	char * base64Pointer;
    long base64Length = BIO_get_mem_data(mem, &base64Pointer);
		
	NSString * base64String = [NSString stringWithCString:base64Pointer
													   length:base64Length];
		
	BIO_free_all(mem);
    return base64String;
}
@end

@implementation NSString (OpenSSLWrapper)

- (NSData *) decodeBase64;
{
    return [self decodeBase64WithNewlines:YES];
}

- (NSData *) decodeBase64WithNewlines:(BOOL)encodedWithNewlines;
{
    BIO * mem = BIO_new_mem_buf((void *) [self cString], [self cStringLength]);
    
    BIO * b64 = BIO_new(BIO_f_base64());
    if (!encodedWithNewlines)
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    mem = BIO_push(b64, mem);
    
    NSMutableData * data = [NSMutableData data];
    char inbuf[512];
    int inlen;
    while ((inlen = BIO_read(mem, inbuf, sizeof(inbuf))) > 0)
        [data appendBytes:inbuf length:inlen];
    
    BIO_free_all(mem);
    return data;
}

- (NSString*)readableSizeForPath
{
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:self traverseLink:YES];
	if (fileAttributes==nil)
		return @"Unknown";
	
    unsigned long long size = [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];

	if (size == 0.) 
		return @"Empty";
	else 
		if (size > 0. && size < 1024.) 
			return [NSString stringWithFormat:@"%lu bytes", size];
	else 
		if (size >= 1024. && size < pow(1024., 2.)) 
			return [NSString stringWithFormat:@"%.1f KB", (size / 1024.)];
	else 
		if (size >= pow(1024., 2.) && size < pow(1024., 3.))
			return [NSString stringWithFormat:@"%.2f MB", (size / pow(1024., 2.))];
	else 
		if (size >= pow(1024., 3.)) 
			return [NSString stringWithFormat:@"%.3f GB", (size / pow(1024., 3.))];
	
	return @"Unknown";
}

@end