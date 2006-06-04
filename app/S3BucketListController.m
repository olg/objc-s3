//
//  S3BucketListController.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3BucketListController.h"
#import "S3Owner.h"
#import "S3Connection.h"
#import "S3Extensions.h"
#import "S3BucketContentController.h"
#import "S3Application.h"

#define SHEET_CANCEL 0
#define SHEET_OK 1



@implementation S3BucketListController

#pragma mark -
#pragma mark Toolbar management

-(void)awakeFromNib
{
	NSToolbar* toolbar = [[[NSToolbar alloc] initWithIdentifier:@"BucketsToolbar"] autorelease];
	[toolbar setDelegate:self];
	[toolbar setVisible:YES];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setSizeMode:NSToolbarSizeModeDefault];
	[toolbar setDisplayMode:NSToolbarDisplayModeDefault];
	[[self window] setToolbar:toolbar];
}

- (NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects: NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		@"Refresh", @"Remove", @"Add", nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([[theItem itemIdentifier] isEqualToString: @"Remove"])
		return [_bucketsController canRemove];
	return YES;
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects: @"Add", @"Remove", NSToolbarFlexibleSpaceItemIdentifier, @"Refresh", nil]; 
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL) flag
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
	
	if ([itemIdentifier isEqualToString: @"Add"])
	{
		[item setLabel: NSLocalizedString(@"Add", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"add.icns"]];
		[item setTarget:self];
		[item setAction:@selector(add:)];
    }
	else if ([itemIdentifier isEqualToString: @"Remove"])
	{
		[item setLabel: NSLocalizedString(@"Remove", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"delete.icns"]];
		[item setTarget:self];
		[item setAction:@selector(remove:)];
    }
	else if ([itemIdentifier isEqualToString: @"Refresh"])
	{
		[item setLabel: NSLocalizedString(@"Refresh", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"refresh.icns"]];
		[item setTarget:self];
		[item setAction:@selector(refresh:)];
    }
	
    return [item autorelease];
}

#pragma mark - 
#pragma mark Misc Delegates

- (IBAction)cancelSheet:(id)sender
{
	[NSApp endSheet:addSheet returnCode:SHEET_CANCEL];
}

- (IBAction)closeSheet:(id)sender
{
	[NSApp endSheet:addSheet returnCode:SHEET_OK];
}

-(void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo
{
}

-(void)operationStateChange:(S3Operation*)o;
{
}

-(void)operationDidFail:(S3Operation*)o
{
	[[self window] presentError:[o error] modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
}

-(void)operationDidFinish:(S3Operation*)o
{
	BOOL b = [o operationSuccess];
	if (!b) {
		[self operationDidFail:o];
		return;
	}
	
	if ([o isKindOfClass:[S3BucketListOperation class]]) {
		[self setBuckets:[(S3BucketListOperation*)o bucketList]];
		[self setBucketsOwner:[(S3BucketListOperation*)o owner]];			
	}
	else
		[self refresh:self];
}

#pragma mark -
#pragma mark Actions

-(IBAction)remove:(id)sender
{
	NSMutableSet* ops = [NSMutableSet set];
	S3Bucket* b;
	NSEnumerator* e = [[_bucketsController selectedObjects] objectEnumerator];
	while (b = [e nextObject])
	{
		S3BucketDeleteOperation* op = [S3BucketDeleteOperation bucketDeletionWithConnection:_connection delegate:self bucket:b];
		[(S3Application*)NSApp logOperation:op];
		[ops addObject:op];
	}
	[self setCurrentOperations:ops];
}

-(IBAction)refresh:(id)sender
{
	S3BucketListOperation* op = [S3BucketListOperation bucketListOperationWithConnection:_connection delegate:self];
	[(S3Application*)NSApp logOperation:op];
	[self setCurrentOperations:[NSMutableSet setWithObject:op]];
}


- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
	if (returnCode==SHEET_OK)
	{
		S3BucketAddOperation* op = [S3BucketAddOperation bucketAddWithConnection:_connection delegate:self name:_name];
		[(S3Application*)NSApp logOperation:op];
		[self setCurrentOperations:[NSMutableSet setWithObject:op]];		
	}
}

-(IBAction)add:(id)sender
{
	[self setName:@"Untitled"];
	[NSApp beginSheet:addSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)open:(id)sender
{
	
	S3Bucket* b;
	NSEnumerator* e = [[_bucketsController selectedObjects] objectEnumerator];
	while (b = [e nextObject])
	{
		S3BucketContentController* c = [[[S3BucketContentController alloc] initWithWindowNibName:@"Objects"] autorelease];
		[c setBucket:b];
		[c setConnection:_connection];
		[c showWindow:self];
		[c retain];
	}
}

#pragma mark -
#pragma mark Key-value coding

- (NSString *)name
{
    return _name; 
}
- (void)setName:(NSString *)aName
{
    [_name release];
    _name = [aName retain];
}

- (S3Connection *)connection
{
    return _connection; 
}
- (void)setConnection:(S3Connection *)aConnection
{
    [_connection release];
    _connection = [aConnection retain];
}

- (S3Owner *)bucketsOwner
{
    return _bucketsOwner; 
}

- (void)setBucketsOwner:(S3Owner *)anBucketsOwner
{
    [_bucketsOwner release];
    _bucketsOwner = [anBucketsOwner retain];
}

- (NSMutableArray *)buckets
{
    return _buckets; 
}

- (void)setBuckets:(NSMutableArray *)aBuckets
{
    [_buckets release];
    _buckets = [aBuckets retain];
}

- (NSMutableSet *)currentOperations
{
    return _currentOperations; 
}
- (void)setCurrentOperations:(NSMutableSet *)aCurrentOperations
{
    [_currentOperations release];
    _currentOperations = [aCurrentOperations retain];
}

-(void)dealloc
{
	[self setName:nil];
	[self setConnection:nil];
	[self setBucketsOwner:nil];
	[self setBuckets:nil];
	[self setCurrentOperations:nil];
	
	[super dealloc];
}

@end
