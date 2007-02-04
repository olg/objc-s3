//
//  S3OperationQueue.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 04/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface S3OperationQueue : NSObject {
	NSMutableArray* _operations;
}

-(void)logOperation:(id)op;
-(void)unlogOperation:(id)op;

@end
