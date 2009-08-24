//
//  S3Application.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3OperationQueue.h"

@class S3ConnectionInfo;

@interface S3Application : NSApplication {
}

- (IBAction)openConnection:(id)sender;
- (IBAction)showOperationConsole:(id)sender;
- (S3OperationQueue *)queue;

@end