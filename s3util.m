//
//  s3util.m
//  s3util
//
//  Created by Gerhard Poul on 2/16/07.
//  Copyright (c) 2007 Gerhard Poul. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "S3Connection.h"
#import "S3OperationRunQueue.h"
#import "S3OperationConsoleLogDelegate.h"
#import "S3BucketListOperation.h"
#import "S3BucketAddOperation.h"
#import "S3BucketDeleteOperation.h"
#import "S3ObjectListOperation.h"
#import "S3ObjectStreamedUploadOperation.h"
#import "S3ObjectDeleteOperation.h"
#import "S3ObjectDownloadOperation.h"
#import "S3Extensions.h"
#import "unistd.h"
#import <openssl/evp.h>

S3Bucket* getS3Bucket(NSString*);
S3Object* getS3Object(NSString*);
NSString* getFileMD5Sum(NSString*);

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// Values to store operations info
	enum { INVALID, LIST, CREATE, DELETE, UPLOAD, DOWNLOAD } mode = INVALID;
	NSString* accessKeyId = nil;
	NSString* bucket = nil;
	int modeParamsCount = 0; // Counts primary modes so we can abort if multiple conflicting modes have been provided.
	NSMutableArray* fileArgs = [NSMutableArray array];

	// Parse command-line arguments
	NSArray *args = [[NSProcessInfo processInfo] arguments];

	// Start at 1 to skip own program name
	for (int i = 1; i < [args count]; i++) {
		if([[args objectAtIndex:i] isEqualToString:@"--bucket"]) {
			bucket = [args objectAtIndex:++i];
			NSLog(@"Bucket has matched. Param: %@", bucket);
		} else if ([[args objectAtIndex:i] isEqualToString:@"--accessKeyID"]) {
			accessKeyId = [args objectAtIndex:++i];
			NSLog(@"AccessKeyID has matched. Param: %@", accessKeyId);
		} else if ([[args objectAtIndex:i] isEqualToString:@"--list"]) {
			mode = LIST;
			NSLog(@"List has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--create"]) {
			mode = CREATE;
			NSLog(@"Create has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--delete"]) {
			mode = DELETE;
			NSLog(@"Delete has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--upload"]) {
			mode = UPLOAD;
			NSLog(@"Upload has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--download"]) {
			mode = DOWNLOAD;
			NSLog(@"Download has matched.");
			modeParamsCount++;
		} else if (![[args objectAtIndex:i] hasPrefix:@"--"]) {
			[fileArgs addObject:[args objectAtIndex:i]];
			NSLog(@"Added '%@' to fileArgs.", [args objectAtIndex:i]);
		} else {
		  NSLog(@"Unmatched param: %@", [args objectAtIndex:i]);
		}
	}
	
	int retval; // Return code
	
	if (mode == 0) {
		// If no valid primary parameter has been provided, exit with appropriate error
		NSLog(@"No valid primary mode has been provided. - aborting operation");
		retval=255;
	} else if (accessKeyId == nil) {
		// If no accessKeyId has been given, we can't authenticate
		NSLog(@"Required accessKeyID parameter has not been provided. - aborting operation");
		retval=250;
	} else if (modeParamsCount > 1) {
		// Multiple primary modes have been provided as arguments
		NSLog(@"Multiple conflicting primary modes have been provided. Please decide on one operation. - aborting operation");
		retval=249;
	} else {
		// Connect to S3
		NSLog(@"Building connection class");
		
		S3Connection* cnx = [[S3Connection alloc] init];
		[cnx setAccessKeyID:accessKeyId];
		
		NSLog(@"Try to get access key from Keychain");
		[cnx trySetupSecretAccessKeyFromKeychain];
		
		S3OperationRunQueue* queue = [[S3OperationRunQueue alloc] init];
		S3OperationConsoleLogDelegate* opDelegate = [[S3OperationConsoleLogDelegate alloc] init];
		[opDelegate setOperationQueue:queue];
		
		if (mode == LIST) {
			if (bucket == nil) {
				// List available buckets
				S3BucketListOperation* op = [S3BucketListOperation bucketListOperationWithConnection:cnx];
				[op setDelegate:opDelegate];
				[queue addToCurrentOperations:op];
			} else {
				// List keys in specified bucket
				S3Bucket* s3Bucket = getS3Bucket(bucket);
				S3ObjectListOperation* op = [S3ObjectListOperation objectListWithConnection:cnx bucket:s3Bucket];
				[op setDelegate:opDelegate];
				[queue addToCurrentOperations:op];
			}
		} else if (mode == CREATE) {
			if (bucket == nil) {
				// Bucket can't be created without a name
				NSLog(@"Bucket can't be created without a name.");
				return 252;
			} else {
				S3BucketAddOperation* op = [S3BucketAddOperation bucketAddWithConnection:cnx name:bucket];
				[op setDelegate:opDelegate];
				[queue addToCurrentOperations:op];
			}
		} else if (mode == DELETE) {
			if (bucket == nil) {
				// Bucket can't be deleted without a name
				NSLog(@"Bucket can't be deleted without a name.");
				return 251;
			} else if ([fileArgs count] > 0) {
				// If there are fileArgs, delete the objects, not the bucket
				NSLog(@"Going to delete objects.");

				S3Bucket* s3Bucket = getS3Bucket(bucket);
				
				NSEnumerator *enumerator = [fileArgs objectEnumerator];
				NSString* fileName;

				while (fileName = [enumerator nextObject]) {
					S3Object* s3Object = getS3Object(fileName);
					S3ObjectDeleteOperation* op = [S3ObjectDeleteOperation objectDeletionWithConnection:cnx bucket:s3Bucket object:s3Object];
					[op setDelegate:opDelegate];
					[queue addToCurrentOperations:op];
				}
			} else {
				// Delete the bucket
				NSLog(@"Going to delete bucket.");
				S3Bucket* s3Bucket = getS3Bucket(bucket);
				S3BucketDeleteOperation* op = [S3BucketDeleteOperation bucketDeletionWithConnection:cnx bucket:s3Bucket];
				[op setDelegate:opDelegate];
				[queue addToCurrentOperations:op];
			}
		} else if (mode == UPLOAD) {
			if (bucket == nil) {
				// Can't upload without knowing destination bucket
				NSLog(@"Bucket name is required for upload.");
				return 253;
			} else if ([fileArgs count] < 1) {
				// Need at least one file to process
				NSLog(@"Upload: No files to process.");
				return 248;
			} else {
				S3Bucket* s3Bucket = getS3Bucket(bucket);
				
				NSEnumerator *enumerator = [fileArgs objectEnumerator];
				NSString* fileName;
				while (fileName = [enumerator nextObject]) {
					NSMutableDictionary* info = [NSMutableDictionary dictionary];
					NSString* filePath = fileName;
					[info setObject:filePath forKey:FILEDATA_PATH];
					[info setObject:[filePath fileSizeForPath] forKey:FILEDATA_SIZE];
					[info safeSetObject:[filePath mimeTypeForPath] forKey:FILEDATA_TYPE withValueForNil:@"application/octet-stream"];
					[info setObject:fileName forKey:FILEDATA_KEY];
					[info setObject:getFileMD5Sum(fileName) forKey:FILEDATA_SUM];
					
					S3ObjectStreamedUploadOperation* op = [S3ObjectStreamedUploadOperation objectUploadWithConnection:cnx bucket:s3Bucket data:info acl:@"private"];
					[op setDelegate:opDelegate];
					[queue addToCurrentOperations:op];
				}
			}
		} else if (mode == DOWNLOAD) {
			if (bucket == nil) {
				// Can't download without knowing source bucket
				NSLog(@"Bucket name required for download.");
				return 247;
			} else if ([fileArgs count] < 1) {
				// Need at least one file to process
				NSLog(@"Download: No files to process.");
				return 246;
			} else {
				S3Bucket* s3Bucket = getS3Bucket(bucket);
				
				char cwdBuffer[512];
				NSString* currentDir = [[NSString alloc] initWithCString:getcwd(cwdBuffer, 512 * sizeof(char))];
				
				NSEnumerator *enumerator = [fileArgs objectEnumerator];
				NSString* fileName;
				while (fileName = [enumerator nextObject]) {
					S3Object* s3Object = getS3Object(fileName);
					NSString* downloadPath = [[currentDir stringByAppendingString:@"/"] stringByAppendingString:fileName];
					S3ObjectDownloadOperation* op = [S3ObjectDownloadOperation objectDownloadWithConnection:cnx bucket:s3Bucket object:s3Object toPath:downloadPath];
					[op setDelegate:opDelegate];
					[queue addToCurrentOperations:op];
				}
			}
		} else {
			NSLog(@"Specified operation has not been implemented yet.");
			return 254;
		}
		
		// Run whatever is in the queue
		[queue run];
		
		// Verify if operation completed successfully
		if ([opDelegate operationFailed]) {
			NSLog(@"Operation failed!");
			retval = 1;
		} else {
			NSLog(@"Operation completed successfully.");
			retval = 0;
		}

		[queue release];
		[opDelegate release];
		
		[cnx release];
	}

    [pool release];
	NSLog(@"Return: %d", retval);
    return retval;
}

S3Bucket* getS3Bucket(NSString* name) {
	S3Bucket* s3Bucket = [[S3Bucket alloc] init];
	[s3Bucket setName:name];
	return s3Bucket;
}

S3Object* getS3Object(NSString* key) {
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:1];
	[dictionary setValue:key forKey:@"key"];
	S3Object* s3Object = [[S3Object alloc] initWithData:nil metaData:dictionary];
	return s3Object;
}

NSString* getFileMD5Sum(NSString* fileName) {
	EVP_MD_CTX mdctx;
	unsigned char md_value[EVP_MAX_MD_SIZE];
	unsigned int md_len;

	NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:fileName];
	NSData* data;
	
	EVP_MD_CTX_init(&mdctx);
	EVP_DigestInit_ex(&mdctx, EVP_md5(), NULL);

	do {
		data = [file readDataOfLength:255];
		EVP_DigestUpdate(&mdctx, [data bytes], [data length]);
	} while([data length] > 0);
	
	EVP_DigestFinal_ex(&mdctx, md_value, &md_len);
	EVP_MD_CTX_cleanup(&mdctx);
	
	char md_char[255];
	
	for (int i=0; i < md_len; i++) snprintf(md_char + i*2, sizeof(md_char) - i*2, "%02x", md_value[i]);
	
	NSLog(@"%s", md_char);
	
	NSString *md_sum = [[NSString alloc] initWithCString:md_char encoding:NSUTF8StringEncoding];
	
	return md_sum;
}
