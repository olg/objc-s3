//
//  S3OperationRunQueue.m
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

#import "S3OperationQueue.h"
#import "S3OperationRunQueue.h"
#import "S3Operation.h"

@implementation S3OperationRunQueue

// Run NSRunLoop until queue is empty or the default timeout has elapsed.
- (void)run
{
	NSLog(@"Running the runloop");
	NSRunLoop *theRL = [NSRunLoop currentRunLoop];
	NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:30];
	NSMutableDictionary *stati = [NSMutableDictionary dictionaryWithCapacity:[[self currentOperations] count]];
	while ([[self currentOperations] count] > 0 && [(NSDate*)[NSDate date] compare:timeout] == NSOrderedAscending) {
		NSEnumerator *enumerator = [[self currentOperations] objectEnumerator];
		S3Operation *op;
		while (op = [enumerator nextObject]) {
			NSString *opStatus = [op status];
			NSString *opKey;
			if ([op respondsToSelector:@selector(getKey)]) {
				opKey = [op getKey];
			} else {
				// Set a generic status key
				opKey = @"Status";
			}
			// Only display an updated status if it has changed.
			if (![[stati valueForKey:opKey] isEqualToString:opStatus]) {
					NSLog(@"%@: %@", opKey, opStatus);
					[stati setValue:opStatus forKey:opKey];
			}
		}
		timeout = [NSDate dateWithTimeIntervalSinceNow:30];
		[theRL runMode:NSDefaultRunLoopMode beforeDate:timeout];
	}
	
	// Check why the while loop above was terminated and act accordingly

	if ([[self currentOperations] count] > 0) {
		NSEnumerator *enumerator = [[self currentOperations] objectEnumerator];
		S3Operation *op;
		while (op = [enumerator nextObject]) {
			if ([[op delegate] respondsToSelector:@selector(setOperationFailed)]) {
				[[op delegate] setOperationFailed];
			} else {
				// This should NOT happen
				NSLog(@"Unable to set operation status to failed. - Return value will NOT be valid!");
			}
		}
	} else {
		NSLog(@"Operations queue empty");
	}
}

@end
