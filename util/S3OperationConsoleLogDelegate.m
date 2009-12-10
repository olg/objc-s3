//
//  S3OperationConsoleLogDelegate.m
//  s3util
//
//  Created by Gerhard Poul on 3/3/07.
//  Copyright (c) 2007, 2008 Gerhard Poul. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of the Organization nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//

#import "S3OperationConsoleLogDelegate.h"
#import "S3OperationQueue.h"
#import "S3BucketListOperation.h"
#import "S3BucketDeleteOperation.h"
#import "S3BucketAddOperation.h"
#import "S3ObjectListOperation.h"
#import "S3ObjectDeleteOperation.h"
#import "S3ObjectStreamedUploadOperation.h"
#import "S3ObjectStreamedUploadOperation+Attributes.h"
#import "S3ObjectDownloadOperation.h"
#import "S3Operation.h"

@implementation S3OperationConsoleLogDelegate

- init
{
	[super init];
	sumArray = [[NSMutableArray alloc] init];
	return self;
}

- (void)dealloc
{
    [_queue removeQueueListener:self];
    [_queue release];
    [verifyDictionary release];
	[sumArray release];
    [super dealloc];
}

- (void)setOperationQueue:(S3OperationQueue *)queue
{
    [_queue removeQueueListener:self];
    [_queue release];
    _queue = [queue retain];
    [_queue addQueueListener:self];
}

- (S3OperationQueue *)operationQueue
{
    return _queue;
}

- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
{
    S3Operation *o = [[notification userInfo] valueForKey:S3OperationObjectKey];
    NSLog(@"operationStateChange was called.");
	NSLog(@"Status: %@", [o status]);
}

- (void)s3OperationDidFail:(NSNotification *)notification
{
    S3Operation *o = [[notification userInfo] valueForKey:S3OperationObjectKey];
	NSLog(@"operationDidFail was called.");
	NSLog(@"Status: %@", [o status]);
	NSLog(@"localizedDescription: %@", [[o error] localizedDescription]);
	[self setOperationFailed:YES];
}

- (void)s3OperationDidFinish:(NSNotification *)notification
{
    S3Operation *o = [[notification userInfo] valueForKey:S3OperationObjectKey];
	NSLog(@"operationDidFinish was called.");
	if ([o isKindOfClass:[S3BucketListOperation class]]) {
		NSMutableArray* buckets = [(S3BucketListOperation*)o bucketList];
		for (int i = 0; i < [buckets count]; i++)
			NSLog(@"  %@", [[buckets objectAtIndex:i] name]);
		NSLog(@"%d bucket%s found.", [buckets count], [buckets count] == 1 ? "" : "s");
	} else if ([o isKindOfClass:[S3ObjectListOperation class]]) {
		NSMutableArray* objects = [(S3ObjectListOperation*)o objects];
		
		if (verifyDictionary == nil) {
			// List objects
			for (int i = 0; i < [objects count]; i++) {
				NSLog(@"   Key: %@", [[objects objectAtIndex:i] operationKey]);
				NSLog(@"   Size: %lld bytes", [(S3Object*)[objects objectAtIndex:i] size]);
				NSDictionary* dict = [[objects objectAtIndex: i] metadata];
				NSLog([dict descriptionWithLocale:nil indent:0]);
			}
			NSLog(@"Objects array has %d entries", [objects count]);
		} else {
			// Verify objects
			for (int i = 0; i < [objects count]; i++) {
				NSString* key = [[objects objectAtIndex:i] operationKey];
				NSString* sum = [verifyDictionary valueForKey:key];
				if (sum != nil) {
					if ([[[[objects objectAtIndex:i] metadata] valueForKey:@"etag"] isEqualToString:sum]) {
						NSLog(@"o %@", key);
					} else {
						NSLog(@"! %@", key);
					}
				} else {
					NSLog(@"+ %@", key);
				}
				[verifyDictionary removeObjectForKey:key];
			}
		}
		
		S3ObjectListOperation* next = [(S3ObjectListOperation*)o operationForNextChunk];
		if (next != nil)
			[[notification object] addToCurrentOperations:next];
		
		// If there are no more entries and we are verifying objects, then list all objects that
		// have not been checked yet and are missing on S3, but are in the local sums file.
		if (next == nil && verifyDictionary != nil) {
			NSArray* missingKeys = [verifyDictionary allKeys];
			
			NSString* key;
			for(key in missingKeys) {
				NSLog(@"- %@", key);
			}
		}
	} else if ([o isKindOfClass:[S3ObjectStreamedUploadOperation class]]) {
		NSString* S3ETag = [(S3ObjectStreamedUploadOperation*)o getETagFromResponse];
		NSLog(@"Status: %@", [o status]);
		NSLog(@"S3 ETag: %@", S3ETag);
		if ([self isSumCorrect:S3ETag filePath:[(S3ObjectStreamedUploadOperation*)o path]]) {
			NSLog(@"Both sums are identical, check OK!");
		} else {
			NSLog(@"ERROR: Checksums don't match!");
			[self setOperationFailed:YES];
		}
	} else if ([o isKindOfClass:[S3BucketDeleteOperation class]] ||
		[o isKindOfClass:[S3BucketAddOperation class]] ||
		[o isKindOfClass:[S3ObjectDeleteOperation class]] ||
		[o isKindOfClass:[S3ObjectDownloadOperation class]]) {
		// TODO: It might make sense to add more details about which UploadOperation completed,
		// but this is not possible with the current core API.
		NSLog(@"Status: %@", [o status]);
		NSLog(@"localizedDescription: %@", [[o error] localizedDescription]);
	}
	else
		NSLog(@"incompatible class was returned.");
}

- (void)setOperationFailed:(BOOL)yn;
{
	operationFailed = yn;
}

- (BOOL)operationFailed
{
	return operationFailed;
}

// Read values from sum store and write them to dictionary
// Returns true on success or false on failure

- (BOOL)readMD5StoreForVerification:(NSString*)persistMD5Store bucket:(NSString*)bucket
{
	verifyDictionary = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* sumsDictionary = [[NSMutableDictionary alloc] init];
	
	NSString* store = [NSString stringWithContentsOfFile:persistMD5Store];
	if (store != nil) {
		NSArray* storeLines = [store componentsSeparatedByString:@"\n"];
		
		NSString *line;
		for(line in storeLines) {
			NSLog(@"String: %@", line);
			if ([line length] > 1) {
				// Find the first and last colon position
				int ifirst, ilast;
				char c = 'a';
				for (ifirst=0; c != ':'; ifirst++)
					c = (char)[line characterAtIndex:ifirst];
				NSLog(@"first colon position: %d", ifirst);
				c = 'a';
				for (ilast=[line length]-1; c != ':'; ilast--)
					c = (char)[line characterAtIndex:ilast];
				NSLog(@"last colon position: %d", ilast);
				
				// Extract the three substrings we need
				NSRange range = { 0, ifirst-1 };
				NSString* bucketName = [line substringWithRange:range];
				NSLog(@"BucketName: %@", bucketName);
				
				range.location = ifirst;
				range.length = ilast - ifirst + 1;
				NSString* keyName = [line substringWithRange:range];
				NSLog(@"KeyName: %@", keyName);
				
				range.location = ilast + 2;
				range.length = [line length] - ilast - 2;
				NSMutableString* cksum = [[NSMutableString alloc] init]; 
				[cksum appendString:@"\""];
				NSString* unquotedcksum = [line substringWithRange:range];
				[cksum appendString:unquotedcksum];
				[cksum appendString:@"\""];
				NSLog(@"CkSum: %@", cksum);
				
				// Write the values to sumsDictionary
				NSMutableString* sumKey = [[NSMutableString alloc] init];
				[sumKey appendString:bucketName];
				[sumKey appendString:@":"];
				[sumKey appendString:keyName];
				[sumsDictionary setValue:unquotedcksum forKey:sumKey];
				
				// Write the values to verifyDictionary if they match the currently verified bucket
				if ([bucketName isEqualToString:bucket])
					[verifyDictionary setValue:cksum forKey:keyName];
			}
		}
		NSLog(@"verifyDictionary: %@", [verifyDictionary description]);
		
		// Truncate sumfile and re-persist sumsDictionary to file
		NSFileHandle* store = [NSFileHandle fileHandleForWritingAtPath:persistMD5Store];
		if (store != nil) {
			[store truncateFileAtOffset:0];
			
			// Iterate through sumsDictionary and write data to file
			NSArray* sumKeys = [sumsDictionary allKeys];
			
			NSString* key;
			for(key in sumKeys) {
				// Prepare data that should be written to file
				char persist_char[2048]; // 256-byte bucket name, 1024-byte key name, 32-byte sum, 4 delimiters
				int persist_len = snprintf(persist_char, sizeof(persist_char), "%s:%s\n", 
					[key UTF8String], [[sumsDictionary valueForKey:key] UTF8String]);
				
				NSData* persist_data = [NSData dataWithBytes:persist_char length:persist_len];
				
				// Write data to file
				[store writeData:persist_data];
			}
			[store closeFile];
		} else {
			NSLog(@"Error while writing to file: %@", persistMD5Store);
			NSLog(@"Sum data could not be re-persisted.");
		}
		return true;
	}
	
	return false;
}

- (NSString*)buildSumString:(NSString*)sum filePath:(NSString*)filePath
{
	NSMutableString* sumAndPath = [NSMutableString stringWithString:sum];
	[sumAndPath appendString:@"-"];
	[sumAndPath appendString:filePath];
	return [NSString stringWithString:sumAndPath];	
}

- (void)storeSumForVerification:(NSString*)sum filePath:(NSString*)filePath
{
	[sumArray addObject:[self buildSumString:sum filePath:filePath]];
}

- (BOOL)isSumCorrect:(NSString*)sum filePath:(NSString*)filePath
{
	return [sumArray containsObject:[self buildSumString:sum filePath:filePath]];
}

@end
