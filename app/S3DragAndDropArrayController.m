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

-(NSArray *)tableView:(NSTableView *)tv namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet
{
	NSLog(@"Drop %@",dropDestination);
	if ([indexSet count]==1)
	{
		id obj = [[self arrangedObjects] objectAtIndex:[indexSet firstIndex]];
		NSString* dest = [delegate exportFile:(id)obj path:[dropDestination path]];
		if (dest!=nil)
			return [NSArray arrayWithObject:dest];
		else
			return nil;
		
	}
	return nil;
}


- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
	if ([rows count] != 1) {
		return NO;
	}
    NSArray *typesArray = [NSArray arrayWithObjects: NSFilesPromisePboardType,nil];
	int row = [[rows objectAtIndex:0] intValue];
	
	
	[pboard declareTypes:typesArray owner:self];
	[pboard setPropertyList:[NSArray arrayWithObject:[[[self arrangedObjects] objectAtIndex:row] key]] forType:NSFilesPromisePboardType];		
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    NSDragOperation dragOp = NSDragOperationCopy;
    [tv setDropRow:-1 dropOperation:NSTableViewDropOn];	
    return dragOp;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
	NSURL *url = [NSURL URLFromPasteboard:[info draggingPasteboard]];	
	if (url && [url isFileURL]) {
		NSString* path = [url path];
		[delegate importFile:path];
/*		id newObject = [self newObject];	
		[self insertObject:newObject atArrangedObjectIndex:0];
		// "new" -- returned with retain count of 1
		[newObject release];
		[newObject takeValue:[url description] forKey:@"url"];
		[newObject takeValue:[NSCalendarDate date] forKey:@"date"];
		// set selected rows to those that were just copied
		[self setSelectionIndex:row];*/
		return YES;		
	}
    return NO;
}

@end

