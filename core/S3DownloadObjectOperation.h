//
//  S3DownloadObjectOperation.h
//  S3-Objc
//
//  Created by Michael Ledford on 11/30/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h"

@class S3ConnectionInfo;
@class S3Object;

@interface S3DownloadObjectOperation : S3Operation {
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o saveTo:(NSString *)filePath;
- (id)initWithConnectionInfo:(S3ConnectionInfo *)c object:(S3Object *)o;

@end
