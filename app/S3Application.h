//
//  S3Application.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class S3OperationQueue;

@interface S3Application : NSApplication {
	NSMutableDictionary* _controlers;
    S3OperationQueue* _queue;
}

-(IBAction)openConnection:(id)sender;
-(IBAction)showOperationConsole:(id)sender;
-(S3OperationQueue*)queue;

@end
