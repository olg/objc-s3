//
//  S3OperationLog.h
//  S3-Objc
//
//  Created by Michael Ledford on 12/1/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class S3Operation;

@interface S3OperationLog : NSObject {
    NSMutableArray *_operations;
}

@property(nonatomic, retain, readwrite) NSMutableArray *operations;

- (void)logOperation:(S3Operation *)o;
- (void)unlogOperation:(S3Operation *)o;

@end
