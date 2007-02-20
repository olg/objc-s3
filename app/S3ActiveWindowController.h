//
//  S3ActiveWindowController.h
//  S3-Objc
//
//  Created by Development Account on 9/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class S3Connection;
@class S3Operation;

// This class handles all operation-based window by maintaining an active/pending operation queue

@interface S3ActiveWindowController : NSWindowController {
	S3Connection* _connection;
    NSMutableArray *_operations;
}

- (S3Connection *)connection;
- (void)setConnection:(S3Connection *)aConnection;

- (void)addToCurrentOperations:(S3Operation*)op;
- (BOOL)hasActiveOperations;

@end
