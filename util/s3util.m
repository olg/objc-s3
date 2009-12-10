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
#import "S3OperationQueue.h"
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

S3Bucket *getS3Bucket(NSString *);
S3Object *getS3Object(NSString *);
NSString *getFileMD5Sum(NSString *);
void persistMD5Sum(NSString *, NSString *, NSString *, NSString *);

typedef enum { 
    INVALID_CMD_MODE,
    LIST_CMD_MODE,
    CREATE_CMD_MODE,
    DELETE_CMD_MODE,
    UPLOAD_CMD_MODE,
    DOWNLOAD_CMD_MODE,
    VERIFY_CMD_MODE
} S3CmdMode;

int main (int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Values to store operations info
	S3CmdMode mode = INVALID_CMD_MODE;
	NSString* accessKeyId = nil;
	NSString* bucket = nil;
	NSString* persistMD5Store = nil;
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
			mode = LIST_CMD_MODE;
			NSLog(@"List has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--create"]) {
			mode = CREATE_CMD_MODE;
			NSLog(@"Create has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--delete"]) {
			mode = DELETE_CMD_MODE;
			NSLog(@"Delete has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--upload"]) {
			mode = UPLOAD_CMD_MODE;
			NSLog(@"Upload has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--download"]) {
			mode = DOWNLOAD_CMD_MODE;
			NSLog(@"Download has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--verify"]) {
			mode = VERIFY_CMD_MODE;
			NSLog(@"Verify has matched.");
			modeParamsCount++;
		} else if ([[args objectAtIndex:i] isEqualToString:@"--persistMD5"]) {
			persistMD5Store = [args objectAtIndex:++i];
			NSLog(@"PersistMD5 has matched. Param: %@", persistMD5Store);
		} else if (![[args objectAtIndex:i] hasPrefix:@"--"]) {
			[fileArgs addObject:[args objectAtIndex:i]];
			NSLog(@"Added '%@' to fileArgs.", [args objectAtIndex:i]);
		} else {
		  NSLog(@"Unmatched param: %@", [args objectAtIndex:i]);
		}
	}
	
	int retval; // Return code
	
	if (mode == INVALID_CMD_MODE) {
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
		
		S3Connection *cnx = [[S3Connection alloc] init];
		[cnx setAccessKeyID:accessKeyId];
		
		NSLog(@"Try to get access key from Keychain");
		[cnx trySetupSecretAccessKeyFromKeychain];
		
		S3OperationQueue *queue = [[S3OperationQueue alloc] init];
		S3OperationConsoleLogDelegate *opDelegate = [[S3OperationConsoleLogDelegate alloc] init];
        [opDelegate setOperationQueue:queue]; 

		if (mode == LIST_CMD_MODE) {
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
		} else if (mode == VERIFY_CMD_MODE) {
			// For verification we need a bucket name and a sum-store
			if (bucket == nil) {
				NSLog(@"Bucket can't be verified without a name.");
				return 245;
			} else if (persistMD5Store == nil) {
				NSLog(@"Verification can't begin without providing a persistMD5Store.");
				return 244;
			} else {
				// Have the opDelegate read the sum-store and make sure it was successful
				if ([opDelegate readMD5StoreForVerification:persistMD5Store bucket:bucket]) {
					// Send a list keys request for specified bucket
					S3Bucket* s3Bucket = getS3Bucket(bucket);
					S3ObjectListOperation* op = [S3ObjectListOperation objectListWithConnection:cnx bucket:s3Bucket];
					[op setDelegate:opDelegate];
					[queue addToCurrentOperations:op];
				} else {
					NSLog(@"Sum store could not be read.");
					return 243;
				}
			}
		} else if (mode == CREATE_CMD_MODE) {
			if (bucket == nil) {
				// Bucket can't be created without a name
				NSLog(@"Bucket can't be created without a name.");
				return 252;
			} else {
				S3BucketAddOperation* op = [S3BucketAddOperation bucketAddWithConnection:cnx name:bucket europeConstraint:false];
				[op setDelegate:opDelegate];
				[queue addToCurrentOperations:op];
			}
		} else if (mode == DELETE_CMD_MODE) {
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

				for (fileName in fileArgs) {
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
		} else if (mode == UPLOAD_CMD_MODE) {
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
				for (fileName in fileArgs) {
					NSMutableDictionary* info = [NSMutableDictionary dictionary];
					NSString* filePath = fileName;
					[info setObject:filePath forKey:FILEDATA_PATH];
					[info setObject:[filePath fileSizeForPath] forKey:FILEDATA_SIZE];
					[info safeSetObject:[filePath mimeTypeForPath] forKey:FILEDATA_TYPE withValueForNil:@"application/octet-stream"];
					[info setObject:fileName forKey:FILEDATA_KEY];

					// Persist the MD5Sum when requested and pass it to UploadOperation
					NSString* md5sum = getFileMD5Sum(fileName);
					if (persistMD5Store != nil)
						persistMD5Sum(persistMD5Store, bucket, fileName, md5sum);
					
					[opDelegate storeSumForVerification:md5sum filePath:filePath];
					
					S3ObjectStreamedUploadOperation* op = [S3ObjectStreamedUploadOperation objectUploadWithConnection:cnx bucket:s3Bucket data:info acl:@"private"];
					[op setDelegate:opDelegate];
					[queue addToCurrentOperations:op];
				}
			}
		} else if (mode == DOWNLOAD_CMD_MODE) {
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
				for (fileName in fileArgs) {
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
        NSLog(@"Running the runloop");
        NSRunLoop *theRL = [NSRunLoop currentRunLoop];
        NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:30];
        NSMutableDictionary *stati = [NSMutableDictionary dictionaryWithCapacity:[[queue currentOperations] count]];
        while ([[queue currentOperations] count] > 0 && [(NSDate*)[NSDate date] compare:timeout] == NSOrderedAscending) {
            NSEnumerator *enumerator = [[queue currentOperations] objectEnumerator];
            S3Operation *op;
            while (op = [enumerator nextObject]) {
                NSString *opStatus = [op status];
                NSString *opKey;
//                if ([op respondsToSelector:@selector(getKey)]) {
//                    opKey = [op getKey];
//                } else {
//                    // Set a generic status key
                    opKey = @"Status";
//                }
                // Only display an updated status if it has changed.
                if (![[stati valueForKey:opKey] isEqualToString:opStatus]) {
					NSLog(@"%@: %@", opKey, opStatus);
					[stati setValue:opStatus forKey:opKey];
                }
            }
            timeout = [NSDate dateWithTimeIntervalSinceNow:30];
            [theRL runMode:NSDefaultRunLoopMode beforeDate:timeout];
        }
        
        if ([[queue currentOperations] count] > 0) {
            NSEnumerator *enumerator = [[queue currentOperations] objectEnumerator];
            S3Operation *op;
            while (op = [enumerator nextObject]) {
                if ([op state] == S3OperationError) {
                    [opDelegate setOperationFailed:YES];
                }
            }
        } else {
            NSLog(@"Operations queue empty");
        }
        
		
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

S3Bucket* getS3Bucket(NSString *name) {
	S3Bucket *s3Bucket = [[S3Bucket alloc] initWithName:name creationDate:nil];
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

// Data written to the persistent file will be written in the format bucket:key:sum
// Using the 1024-byte limitation of key names as a delimiter didn't make sense and colons
// are not allowed in bucket names due to DNS restrictions and will never occur in MD5 hashes.
// When parsing this file you have to be careful to only use the first colon from the front and
// the last column from the back as delimiters as there might be colons in the key name.

void persistMD5Sum(NSString* persistMD5Store, NSString* bucket, NSString* fileName, NSString* md5sum) {
	NSLog(@"Persisting MD5 sum of %@ in bucket %@ to %@", fileName, bucket, persistMD5Store);
	
	// Prepare data that should be written to file
	char persist_char[2048]; // 256-byte bucket name, 1024-byte key name, 32-byte sum, 4 delimiters
	int persist_len = snprintf(persist_char, sizeof(persist_char), "%s:%s:%s\n", 
		[bucket UTF8String], [fileName UTF8String], [md5sum UTF8String]);
	
	NSData* persist_data = [NSData dataWithBytes:persist_char length:persist_len];
	
	NSFileHandle* store = [NSFileHandle fileHandleForWritingAtPath:persistMD5Store];
	if (store != nil) {
		[store seekToEndOfFile];
		[store writeData:persist_data];
		[store closeFile];
	} else {
		NSFileManager* fm = [NSFileManager defaultManager];
		// There is some weird behavior when the file exists, but you don't have permission, but the
		// OS let's the NSFileManager write there anyway when creating a new file and this was the simplest
		// logic I could come up with.
		if (![fm fileExistsAtPath:persistMD5Store]) {
			if (![fm createFileAtPath:persistMD5Store contents:persist_data attributes:nil]) {
				NSLog(@"Error2 while writing to file: %@", persistMD5Store);
				NSLog(@"Sum data could not be persisted.");
			}
		} else {
			NSLog(@"Error while writing to file: %@", persistMD5Store);
			NSLog(@"Sum data could not be persisted.");
		}
	}
}
