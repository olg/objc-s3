//
//  S3Application.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface S3Application : NSApplication {
	NSMutableArray* _operations;
	NSMutableDictionary* _controlers;
}

-(IBAction)openConnection:(id)sender;
-(IBAction)showOperationConsole:(id)sender;

-(void)logOperation:(id)op;
-(void)unlogOperation:(id)op;

@end
