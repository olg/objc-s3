//
//  S3AppKitExtensions.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/11/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"

@interface NSArrayController (ToolbarExtensions)
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
@end

@interface NSHTTPURLResponse (Logging)
- (NSString *)httpStatus;
- (NSArray *)headersReceived;
@end

@interface NSURLRequest (Logging)
- (NSArray *)headersSent;
@end 


