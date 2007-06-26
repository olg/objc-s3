//
//  S3OperationConsoleLogDelegate.m
//  s3util
//
//  Created by Gerhard Poul on 3/3/07.
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

#import "S3OperationConsoleLogDelegate.h"
#import "S3BucketListOperation.h"
#import "S3BucketDeleteOperation.h"
#import "S3BucketAddOperation.h"
#import "S3ObjectListOperation.h"
#import "S3ObjectDeleteOperation.h"
#import "S3ObjectStreamedUploadOperation.h"
#import "S3ObjectDownloadOperation.h"

@implementation S3OperationConsoleLogDelegate

- (void)operationStateDidChange:(S3Operation*)o
{
	[_queue operationStateDidChange:o];
    NSLog(@"operationStateChange was called.");
	NSLog(@"Status: %@", [o status]);
}

- (void)operationDidFail:(S3Operation*)o
{
	[_queue operationDidFail:o];
	NSLog(@"operationDidFail was called.");
	NSLog(@"Status: %@", [o status]);
	NSLog(@"localizedDescription: %@", [[o error] localizedDescription]);
	[self setOperationFailed];
}

- (void)operationDidFinish:(S3Operation*)o
{
	[_queue operationDidFinish:o];
	NSLog(@"operationDidFinish was called.");
	if ([o isKindOfClass:[S3BucketListOperation class]]) {
		NSMutableArray* buckets = [(S3BucketListOperation*)o bucketList];
		for (int i = 0; i < [buckets count]; i++)
			NSLog(@"  %@", [[buckets objectAtIndex:i] name]);
		NSLog(@"%d bucket%s found.", [buckets count], [buckets count] == 1 ? "" : "s");
	} else if ([o isKindOfClass:[S3ObjectListOperation class]]) {
		// List objects
		NSMutableArray* objects = [(S3ObjectListOperation*)o objects];
		for (int i = 0; i < [objects count]; i++) {
			NSLog(@"   Key: %@", [[objects objectAtIndex:i] key]);
			NSLog(@"   Size: %lld bytes", [(S3Object*)[objects objectAtIndex:i] size]);
			NSDictionary* dict = [[objects objectAtIndex: i] metadata];
			NSLog([dict descriptionWithLocale:nil indent:0]);
		}
		NSLog(@"Objects array has %d entries", [objects count]);
		
		S3ObjectListOperation* next = [(S3ObjectListOperation*)o operationForNextChunk];
		if (next != nil)
			[_queue addToCurrentOperations:next];
	} else if ([o isKindOfClass:[S3ObjectStreamedUploadOperation class]]) {
		NSString* S3ETag = [(S3ObjectStreamedUploadOperation*)o getETagFromResponse];
		NSString* LocalSum = [(S3ObjectStreamedUploadOperation*)o getLocalSum];
		NSLog(@"Status: %@", [o status]);
		NSLog(@"S3-Calculated ETag: %@", S3ETag);
		NSLog(@"Local-Calc MD5-SUM: %@", LocalSum);
		if ([S3ETag isEqualToString:LocalSum]) {
			NSLog(@"Both sums are identical, check OK!");
		} else {
			NSLog(@"ERROR: Checksums don't match!");
			[self setOperationFailed];
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

- (void)setOperationQueue:(S3OperationQueue*)q
{
	_queue = q;
}

- (void)setOperationFailed
{
	operationFailed = YES;
}

- (BOOL)operationFailed
{
	return operationFailed;
}

@end
