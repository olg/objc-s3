//
//  S3ActiveWindowController.h
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class S3ConnectionInfo;
@class S3Operation;

// This class handles all operation-based window by maintaining an active/pending operation queue

@interface S3ActiveWindowController : NSWindowController {
	S3ConnectionInfo *_connectionInfo;
    NSMutableArray *_operations;
    NSMutableDictionary *_redirectConnectionInfoMappings;
}

- (S3ConnectionInfo *)connectionInfo;
- (void)setConnectionInfo:(S3ConnectionInfo *)aConnection;

- (void)addToCurrentOperations:(S3Operation *)op;
- (BOOL)hasActiveOperations;

@end
