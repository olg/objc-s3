//
//  S3ObjectDeleteOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3NSURLConnectionOperation.h"
#import "S3Connection.h"
#import "S3Object.h"

@interface S3ObjectDeleteOperation : S3NSURLConnectionOperation

+(S3ObjectDeleteOperation*)objectDeletionWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b object:(S3Object*)o;

@end
