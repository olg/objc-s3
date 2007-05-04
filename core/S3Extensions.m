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

@implementation NSArray (Comfort)

- (NSArray *)expandPaths
{
	NSMutableArray *a = [NSMutableArray array];
	NSEnumerator *e = [self objectEnumerator];
	NSString *path;
	BOOL dir;
	
	while(path = [e nextObject])
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir])
		{		
			if (!dir)
				[a addObject:path];
			else
			{
				NSString *file;
				NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
				
				while (file = [dirEnum nextObject]) 
				{
					if (![[file lastPathComponent] hasPrefix:@"."]) 
					{
						NSString* fullPath = [path stringByAppendingPathComponent:file];
						
						if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&dir])
							if (!dir)
								[a addObject:fullPath];
					}
				}
			}
		}
	}
	return a;
}


- (BOOL)hasObjectSatisfying:(SEL)aSelector withArgument:(id)argument;
{
    NSEnumerator *e = [self objectEnumerator];
    id o;
    while (o = [e nextObject])
    {
        if ([o performSelector:aSelector withObject:argument])
            return TRUE;
    }
    return FALSE;
}

@end

@implementation NSDictionary (URL)

- (NSString *)queryString
{
    if ([self count]==0)
        return @"";
    
    NSMutableString *s = [NSMutableString string];
    NSArray *keys = [self allKeys];
    NSString *k;
    int i;

    k = [keys objectAtIndex:0];
    [s appendString:@"?"];
    [s appendString:[k stringByEscapingHTTPReserved]];
    [s appendString:@"="];
    [s appendString:[[self objectForKey:k] stringByEscapingHTTPReserved]];
    
    for (i=1;i<[keys count];i++)
    {
        k = [keys objectAtIndex:i];
        [s appendString:@"&"];
        [s appendString:[k stringByEscapingHTTPReserved]];
        [s appendString:@"="];
        [s appendString:[[self objectForKey:k] stringByEscapingHTTPReserved]];
    }
    return s;
}

@end

@implementation NSMutableDictionary (Comfort)

- (void)safeSetObject:(id)o forKey:(NSString *)k
{
	if ((o==nil)||(k==nil))
		return;
	[self setObject:o forKey:k];
}

- (void)safeSetObject:(id)o forKey:(NSString *)k withValueForNil:(id)d
{
	if (k==nil)
		return;
	if (o!=nil)
		[self setObject:o forKey:k];
	else
		[self setObject:d forKey:k];
}

@end

@implementation NSXMLElement (Comfort)

- (NSXMLElement *)elementForName:(NSString *)n
{
	NSArray *a = [self elementsForName:n];
	if ([a count]>0)
		return [a objectAtIndex:0];
	else 
		return nil;
}

- (NSNumber *)longLongNumber
{
	return [NSNumber numberWithLongLong:[[self stringValue] longLongValue]];
}

- (NSNumber *)boolNumber
{
	// I don't trust the output format, the S3 doc sometimes mentions a "false;"
	if ([[self stringValue] rangeOfString:@"true" options:NSCaseInsensitiveSearch].location!=NSNotFound)
		return [NSNumber numberWithBool:TRUE];
	else
		return [NSNumber numberWithBool:FALSE];
}

- (NSCalendarDate *)dateValue
{
	id s = [[self stringValue] stringByAppendingString:@" +0000"];
	id d = [NSCalendarDate dateWithString:s calendarFormat:@"%Y-%m-%dT%H:%M:%S.%FZ %z"];
	return d;
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

- (NSData *)sha1HMacWithKey:(NSString *)key
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
	
- (NSString *)encodeBase64
{
    return [self encodeBase64WithNewlines:NO];
}

- (NSString *) encodeBase64WithNewlines:(BOOL) encodeWithNewlines
{
    BIO *mem = BIO_new(BIO_s_mem());
	BIO *b64 = BIO_new(BIO_f_base64());
    if (!encodeWithNewlines)
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    mem = BIO_push(b64, mem);

	BIO_write(mem, [self bytes], [self length]);
    BIO_flush(mem);
		
	char *base64Pointer;
    long base64Length = BIO_get_mem_data(mem, &base64Pointer);
		
	NSString *base64String = [NSString stringWithCString:base64Pointer
													   length:base64Length];
		
	BIO_free_all(mem);
    return base64String;
}
@end

@implementation NSString (OpenSSLWrapper)

- (NSData *)decodeBase64;
{
    return [self decodeBase64WithNewlines:YES];
}

- (NSData *)decodeBase64WithNewlines:(BOOL)encodedWithNewlines;
{
    BIO *mem = BIO_new_mem_buf((void *) [self cString], [self cStringLength]);
    
    BIO *b64 = BIO_new(BIO_f_base64());
    if (!encodedWithNewlines)
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    mem = BIO_push(b64, mem);
    
    NSMutableData *data = [NSMutableData data];
    char inbuf[512];
    int inlen;
    while ((inlen = BIO_read(mem, inbuf, sizeof(inbuf))) > 0)
        [data appendBytes:inbuf length:inlen];
    
    BIO_free_all(mem);
    return data;
}

- (NSNumber *)fileSizeForPath
{
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:self traverseLink:YES];
	if (fileAttributes==nil)
		return [NSNumber numberWithLongLong:0];
    else
        return [fileAttributes objectForKey:NSFileSize];
}

- (NSString *)readableSizeForPath
{
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:self traverseLink:YES];
	if (fileAttributes==nil)
		return @"Unknown";
	
    return [[fileAttributes objectForKey:NSFileSize] readableFileSize];
}

- (NSString *)mimeTypeForPath
{
	FSRef fsRef;
	CFStringRef utiType;
	OSStatus err;
	
	err= FSPathMakeRef((const UInt8 *)[self fileSystemRepresentation], &fsRef, NULL);
	if(err != noErr)
		return nil;
	LSCopyItemAttribute(&fsRef,kLSRolesAll,kLSItemContentType, (CFTypeRef*)&utiType);
	if(err != noErr)
		return nil;
	CFStringRef mimeType = UTTypeCopyPreferredTagWithClass(utiType, kUTTagClassMIMEType);
	return [(NSString*)mimeType autorelease];
}

+ (NSString *)readableSizeForPaths:(NSArray *)files
{
	NSEnumerator *e = [files objectEnumerator];
	NSString *path;
	unsigned long long total = 0;
	
	while (path = [e nextObject])
	{
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
		if (fileAttributes!=nil)
			total = total + [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];				
	}
	
    return [NSString readableFileSizeFor:total];
}

+ (NSString *)readableFileSizeFor:(unsigned long long) size
{
	if (size == 0.) 
		return @"Empty";
	else 
		if (size > 0. && size < 1024.) 
			return [NSString stringWithFormat:@"%qu bytes", size];
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

+ (NSString *)commonPathComponentInPaths:(NSArray *)paths
{
	NSString *prefix = [NSString commonPrefixWithStrings:paths]; 
	NSRange r = [prefix rangeOfString:@"/" options:NSBackwardsSearch];
	if (r.location!=NSNotFound)
		return [prefix substringToIndex:(r.location+1)];
	else
		return @"";
}

+ (NSString *)commonPrefixWithStrings:(NSArray *)strings
{
	int sLength = [strings count];
	int i,j;
	
	if (sLength == 1)
		return [strings objectAtIndex:0];
	else 
	{
		NSString* prefix = [strings objectAtIndex:0];
		int maxLength = [prefix length];
		
		for (i = 1; i < sLength; i++)
			if ([[strings objectAtIndex:i] length] < maxLength)
				maxLength = [[strings objectAtIndex:i] length];
		
		for (i = 0; i < maxLength; i++) {
			unichar c = [prefix characterAtIndex:i];
			
			for (j = 1; j < sLength; j++) {
				NSString* compareString = [strings objectAtIndex:j];
				
				if ([compareString characterAtIndex:i] != c)
					if (i == 0)
						return @"";
					else
						return [prefix substringToIndex:i];
			}
		}
		
		return [prefix substringToIndex:maxLength];
	}
}

@end


@implementation NSNumber (Comfort)

- (NSString *)readableFileSize
{
	return [NSString readableFileSizeFor:[self unsignedLongLongValue]];
}

@end

@implementation NSString (URL)

- (NSString *)stringByEscapingHTTPReserved
{
	// Escape all Reserved characters from rfc 2396 section 2.2
	// except "/" since that's used explicitly in format strings.
	CFStringRef escapeChars = (CFStringRef)@";?:@&=+$,";
	return [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
			(CFStringRef)self, NULL, escapeChars, kCFStringEncodingUTF8)
			autorelease];
}

@end