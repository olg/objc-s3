//
//  S3BucketAddOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3NSURLConnectionOperation.h"
#import "S3Connection.h"


@interface S3BucketAddOperation : S3NSURLConnectionOperation

+(S3BucketAddOperation*)bucketAddWithConnection:(S3Connection*)c delegate:(id<S3OperationDelegate>)d name:(NSString*)name;

@end

