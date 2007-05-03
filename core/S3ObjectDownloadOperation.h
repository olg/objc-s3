//
//  S3ObjectDownloadOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"

@class S3Owner;
@class S3Object;
@class S3Bucket;
@class S3Connection;
@class S3TransferRateCalculator;

@interface S3ObjectDownloadOperation : S3Operation 
{
	NSHTTPURLResponse *_response;
	NSURLRequest *_request;
	NSURLDownload *_urlDownloadConnection;
    S3TransferRateCalculator *_rateCalculator;
}

+ (S3ObjectDownloadOperation *)objectDownloadWithConnection:(S3Connection *)c bucket:(S3Bucket *)b object:(S3Object *)o toPath:(NSString *)path;

@end