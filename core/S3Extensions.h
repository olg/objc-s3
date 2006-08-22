//
//  S3Extensions.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/31/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (Comfort)

- (long long)longLongValue;

@end


@interface NSMutableDictionary (Comfort)

-(void)safeSetObject:(id)o forKey:(NSString*)k;

@end

@interface NSSet (Comfort)

-(BOOL)containsObjectOfClass:(Class)c;

@end


@interface NSXMLElement (Comfort)

-(NSXMLElement*)elementForName:(NSString*)n;
-(NSNumber*)longLongNumber;
-(NSNumber*)boolNumber;
-(NSCalendarDate*)dateValue;

@end


@interface NSData (OpenSSLWrapper)

- (NSData *)md5Digest;
- (NSData *)sha1Digest;
- (NSData *)sha1HMacWithKey:(NSString*)key;

- (NSString *)encodeBase64;
- (NSString *)encodeBase64WithNewlines: (BOOL)encodeWithNewlines;

@end

@interface NSString (OpenSSLWrapper)

- (NSData *) decodeBase64;
- (NSData *) decodeBase64WithNewlines:(BOOL)encodedWithNewlines;

- (NSString*)readableSizeForPath;

@end

@interface NSNumber (Comfort)

-(NSString*)readableFileSize;

@end