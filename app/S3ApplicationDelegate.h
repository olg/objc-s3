//
//  S3ApplicationDelegate.h
//  S3-Objc
//
//  Created by Michael Ledford on 9/11/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class S3ConnectionInfo;
@class S3OperationQueue;
@class S3OperationLog;

@interface S3ApplicationDelegate : NSObject {
    NSMutableDictionary *_controllers;
    S3OperationQueue *_queue;
    S3OperationLog *_operationLog;
    NSMutableDictionary *_authenticationCredentials;
}

- (IBAction)openConnection:(id)sender;
- (IBAction)showOperationConsole:(id)sender;
- (S3OperationQueue *)queue;
- (S3OperationLog *)operationLog;

- (void)setAuthenticationCredentials:(NSDictionary *)authDict forConnectionInfo:(S3ConnectionInfo *)connInto;
- (void)removeAuthenticationCredentialsForConnectionInfo:(S3ConnectionInfo *)connInfo;
@end
