//
//  S3DragAndDropArrayController.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 8/17/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3DragAndDropArrayController.h"


@implementation S3DragAndDropArrayController

- (void)awakeFromNib
{
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	[super awakeFromNib];
}

-(void)setFileOperationsDelegate:(id)d
{
	delegate = d;
}

-(BOOL)validateDraggingInfo:(id <NSDraggingInfo>)info 
{
	NSURL *url = [NSURL URLFromPasteboard:[info draggingPasteboard]];	
	if (url && [url isFileURL]) 
	{
		NSString* path = [url path];
		if ([delegate acceptFileForImport:path])
			return YES;
	}
	return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if ([self validateDraggingInfo:info])
	{
		[tv setDropRow:-1 dropOperation:NSTableViewDropOn];	
		return NSDragOperationCopy;
	}
	else
		return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
	// Probably over-zealous, it' unlikely that the drag info would change between validate and accept drop
	if ([self validateDraggingInfo:info])
	{
		[delegate importFile:[[NSURL URLFromPasteboard:[info draggingPasteboard]] path]];
		return YES;
	}
	else
		return NO;
}

@end

