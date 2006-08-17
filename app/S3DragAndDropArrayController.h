//
//  S3DragAndDropArrayController.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/17/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface S3DragAndDropArrayController : NSArrayController
{
    IBOutlet NSTableView *tableView;
	id delegate;
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;

- (void)setFileOperationsDelegate:(id)d;

@end
