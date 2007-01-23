//
//  S3ObjectUploadOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/16/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3NSURLConnectionOperation.h"
#import "S3Connection.h"

@interface S3ObjectUploadOperation : S3NSURLConnectionOperation 

+(S3ObjectUploadOperation*)objectUploadWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d bucket:(S3Bucket*)b data:(NSDictionary*)data acl:(NSString*)acl;

@end

