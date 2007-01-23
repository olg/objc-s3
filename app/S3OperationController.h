//
//  S3OperationController.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/8/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"

@interface S3OperationController : NSWindowController {
	IBOutlet NSArrayController* _operationsArrayController;
	IBOutlet NSWindow* _infoPanel;
}

@end


