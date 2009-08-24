//
//  S3OperationController.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/8/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3OperationController.h"
#import "S3ApplicationDelegate.h"
#import "S3ValueTransformers.h"

#pragma mark -
#pragma mark The operation console/inspector itself

@implementation S3OperationController

+ (void)initialize
{
	[NSValueTransformer setValueTransformer:[[S3OperationSummarizer new] autorelease] forName:@"S3OperationSummarizer"];
}

-(void)awakeFromNib
{
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"OperationConsoleToolbar"] autorelease];
	[toolbar setDelegate:self];
	[toolbar setVisible:YES];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setSizeMode:NSToolbarSizeModeSmall];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[[self window] setToolbar:toolbar];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects: NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		@"Stop", @"Remove", @"Info", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects: @"Info", @"Remove", NSToolbarFlexibleSpaceItemIdentifier, @"Stop", nil]; 
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([[theItem itemIdentifier] isEqualToString:@"Remove"]) {	
		if (![_operationsArrayController canRemove]) {
			return NO;
        }
		
		NSEnumerator *e = [[_operationsArrayController selectedObjects] objectEnumerator];
		S3Operation *op;
		while (op = [e nextObject]) {
			if (([op state]==S3OperationActive)||([op state]==S3OperationPending)) {
				return NO;
            }
		}
		return YES;
	}
	if ([[theItem itemIdentifier] isEqualToString:@"Stop"]) {	
		NSEnumerator *e = [[_operationsArrayController selectedObjects] objectEnumerator];
		S3Operation *op;
		while (op = [e nextObject]) {
			if (([op state]==S3OperationActive)||([op state]==S3OperationPending)) {
				return YES;
            }
		}
		return NO;
	}
    if ([[theItem itemIdentifier] isEqualToString:@"Info"]) {
        if ([[_operationsArrayController selectedObjects] count] != 1) {
            return NO;
        }
    }

	return YES;
}

- (IBAction)remove:(id)sender;
{
	[_operationsArrayController remove:sender];
}

- (IBAction)stop:(id)sender;
{
	NSEnumerator *e = [[_operationsArrayController selectedObjects] objectEnumerator];
	S3Operation *op;
	while (op = [e nextObject]) 
	{
		if (([op state]==S3OperationActive)||([op state]==S3OperationPending)) {
			[op stop:self];            
        }
	}	
}

- (IBAction)info:(id)sender
{
    [_infoPanel orderFront:self];
}

- (NSToolbarItem*)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
	
	if ([itemIdentifier isEqualToString: @"Stop"])
	{
		[item setLabel: NSLocalizedString(@"Stop", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"stop.icns"]];
		[item setTarget:self];
		[item setAction:@selector(stop:)];
    }
	else if ([itemIdentifier isEqualToString: @"Remove"])
	{
		[item setLabel: NSLocalizedString(@"Remove", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"delete.icns"]];
		[item setTarget:self];
		[item setAction:@selector(remove:)];
    }
	else if ([itemIdentifier isEqualToString: @"Info"])
	{
		[item setLabel: NSLocalizedString(@"Info", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"info.icns"]];
		[item setTarget:self];
		[item setAction:@selector(info:)];
    }
	
    return [item autorelease];
}
@end
