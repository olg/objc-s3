//
//  S3CopyObjectOperation.h
//  S3-Objc
//
//  Created by Michael Ledford on 12/11/09.
//  Copyright 2009 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3Operation.h"

@interface S3CopyObjectOperation : S3Operation {
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)c from:(S3Object *)source to:(S3Object *)destination;

@end
