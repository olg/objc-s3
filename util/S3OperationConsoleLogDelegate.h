//
//  S3OperationConsoleLogDelegate.h
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

#import <Cocoa/Cocoa.h>

@class S3OperationQueue;

@interface S3OperationConsoleLogDelegate : NSObject {
	S3OperationQueue* _queue;
	BOOL operationFailed;
	NSMutableDictionary *verifyDictionary;
	NSMutableArray *sumArray;
}


- (void)setOperationQueue:(S3OperationQueue *)queue;
- (S3OperationQueue *)operationQueue;
- (void)setOperationFailed:(BOOL)yn;
- (BOOL)operationFailed;
- (BOOL)readMD5StoreForVerification:(NSString*)persistMD5Store bucket:(NSString*)bucket;
- (void)storeSumForVerification:(NSString*)sum filePath:(NSString*)filePath;
- (BOOL)isSumCorrect:(NSString*)sum filePath:(NSString*)filePath;

@end
