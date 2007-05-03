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

- (void)setFileOperationsDelegate:(id)d
{
	delegate = d;
}

- (BOOL)validateDraggingInfo:(id <NSDraggingInfo>)info 
{
    if ([[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType]) 
    {
        NSArray *files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        int numberOfFiles = [files count];
        int i;
        for (i=0;i<numberOfFiles;i++)
        {
            if ([delegate acceptFileForImport:[files objectAtIndex:i]])
                return YES;
        }
    }
    
	return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if ([self validateDraggingInfo:info])
	{
		[tv setDropRow:-1 dropOperation:NSTableViewDropOn];	
		return NSDragOperationCopy;
	}
	else
		return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    if ([[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType]) 
    {
        NSArray *files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		[delegate importFiles:files withDialog:TRUE];
        return YES;
	}
	else
		return NO;
}

@end

