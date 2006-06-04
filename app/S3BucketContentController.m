//
//  S3BucketContentController.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3BucketContentController.h"
#import "S3Extensions.h"
#import "S3Connection.h"
#import "S3Bucket.h"
#import "S3ObjectOperations.h"
#import "S3Application.h"

#define SHEET_CANCEL 0
#define SHEET_OK 1

#define ACL_PRIVATE @"private"

@implementation S3BucketContentController

#pragma mark - 
#pragma mark Toolbar management

-(void)awakeFromNib
{
	NSToolbar* toolbar = [[[NSToolbar alloc] initWithIdentifier:@"ObjectsToolbar"] autorelease];
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
		@"Refresh", @"Upload", @"Download", @"Remove", nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([[theItem itemIdentifier] isEqualToString: @"Remove"])
		return [_objectsController canRemove];
	if ([[theItem itemIdentifier] isEqualToString: @"Download"])
		return [_objectsController canRemove];
	return YES;
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects: @"Upload", @"Download", @"Remove", NSToolbarFlexibleSpaceItemIdentifier, @"Refresh", nil]; 
}

- (NSToolbarItem*)toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL) flag
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
	
	if ([itemIdentifier isEqualToString: @"Upload"])
	{
		[item setLabel: NSLocalizedString(@"Upload", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"upload.icns"]];
		[item setTarget:self];
		[item setAction:@selector(upload:)];
    }
	if ([itemIdentifier isEqualToString: @"Download"])
	{
		[item setLabel: NSLocalizedString(@"Download", nil)];
		[item setPaletteLabel: [item label]];
		[item setImage: [NSImage imageNamed: @"download.icns"]];
		[item setTarget:self];
		[item setAction:@selector(download:)];
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


-(void)windowDidLoad
{
	[self refresh:self];
}

- (IBAction)cancelSheet:(id)sender
{
	[NSApp endSheet:uploadSheet returnCode:SHEET_CANCEL];
}

- (IBAction)closeSheet:(id)sender
{
	[NSApp endSheet:uploadSheet returnCode:SHEET_OK];
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

-(void)operationDidFinish:(S3Operation*)op
{
	BOOL b = [op operationSuccess];
	if (!b)	{	
		[self operationDidFail:op];
		return;
	}

	if ([op isKindOfClass:[S3ObjectDownloadOperation class]]) {
		NSData* d = [(S3ObjectDownloadOperation*)op data];
		NSSavePanel* sp = [NSSavePanel savePanel];
		int runResult;
		NSString* n = [[(S3ObjectDownloadOperation*)op object] key];
		if (n==nil) n = @"Untitled";
		runResult = [sp runModalForDirectory:nil file:n];
		
		if (runResult == NSOKButton) {
			if (![d writeToFile:[sp filename] atomically:YES])
				NSBeep();
		}
	}
	if ([op isKindOfClass:[S3ObjectListOperation class]]) {
		[self setObjects:[(S3ObjectListOperation*)op objects]];
		[self setObjectsInfo:[(S3ObjectListOperation*)op metadata]];
	}
	if ([op isKindOfClass:[S3ObjectUploadOperation class]]||[op isKindOfClass:[S3ObjectDeleteOperation class]])
		[self refresh:self];
}

#pragma mark -
#pragma mark Actions

-(IBAction)refresh:(id)sender
{
	S3ObjectListOperation* op = [S3ObjectListOperation objectListWithConnection:_connection delegate:self bucket:_bucket];
	[(S3Application*)NSApp logOperation:op];
	[self setCurrentOperations:[NSMutableSet setWithObject:op]];
}

-(IBAction)remove:(id)sender
{
	NSMutableSet* ops = [NSMutableSet set];
	S3Object* b;
	NSEnumerator* e = [[_objectsController selectedObjects] objectEnumerator];
	while (b = [e nextObject])
	{
		S3ObjectDeleteOperation* op = [S3ObjectDeleteOperation objectDeletionWithConnection:_connection delegate:self bucket:_bucket object:b];
		[(S3Application*)NSApp logOperation:op];
		[ops addObject:op];
	}
	[self setCurrentOperations:ops];
}

-(IBAction)download:(id)sender
{
	NSMutableSet* ops = [NSMutableSet set];
	S3Object* b;
	NSEnumerator* e = [[_objectsController selectedObjects] objectEnumerator];
	while (b = [e nextObject])
	{
		S3ObjectDownloadOperation* op = [S3ObjectDownloadOperation objectDownloadWithConnection:_connection delegate:self bucket:_bucket object:b];
		[(S3Application*)NSApp logOperation:op];
		[ops addObject:op];
	}
	[self setCurrentOperations:ops];
}


-(IBAction)upload:(id)sender
{
	NSOpenPanel *oPanel = [[NSOpenPanel openPanel] retain];
	[oPanel setAllowsMultipleSelection:NO];
	[oPanel beginForDirectory:nil file:nil types:nil modelessDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
	if (returnCode==SHEET_OK)
	{
		NSData* data = [NSData dataWithContentsOfFile:[self uploadFilename]];
		S3ObjectUploadOperation* op = [S3ObjectUploadOperation objectUploadWithConnection:_connection delegate:self bucket:_bucket key:[self uploadKey] data:data acl:[self uploadACL]];
		[(S3Application*)NSApp logOperation:op];
		[self setCurrentOperations:[NSMutableSet setWithObject:op]];
	}
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSArray *files = [panel filenames];
	
	if ((returnCode != NSOKButton)||([files count]!=1)) {
		[panel release];
		return;
	}
	[panel release];
	
	[self setUploadFilename:[files objectAtIndex:0]];
	[self setUploadACL:ACL_PRIVATE];
	[self setUploadKey:[[self uploadFilename] lastPathComponent]];
	[self setUploadSize:[[self uploadFilename] readableSizeForPath]];
	[NSApp beginSheet:uploadSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

#pragma mark -
#pragma mark Key-value coding

- (NSMutableArray *)objects
{
    return _objects; 
}
- (void)setObjects:(NSMutableArray *)aObjects
{
    [_objects release];
    _objects = [aObjects retain];
}


- (NSMutableDictionary *)objectsInfo
{
    return _objectsInfo; 
}
- (void)setObjectsInfo:(NSMutableDictionary *)aObjectsInfo
{
    [_objectsInfo release];
    _objectsInfo = [aObjectsInfo retain];
}


- (S3Bucket *)bucket
{
    return _bucket; 
}
- (void)setBucket:(S3Bucket *)aBucket
{
    [_bucket release];
    _bucket = [aBucket retain];
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


- (NSMutableSet *)currentOperations
{
    return _currentOperations; 
}
- (void)setCurrentOperations:(NSMutableSet *)aCurrentOperations
{
    [_currentOperations release];
    _currentOperations = [aCurrentOperations retain];
}


- (NSString *)uploadKey
{
    return _uploadKey; 
}
- (void)setUploadKey:(NSString *)anUploadKey
{
    [_uploadKey release];
    _uploadKey = [anUploadKey retain];
}


- (NSString *)uploadACL
{
    return _uploadACL; 
}
- (void)setUploadACL:(NSString *)anUploadACL
{
    [_uploadACL release];
    _uploadACL = [anUploadACL retain];
}


- (NSString *)uploadFilename
{
    return _uploadFilename; 
}
- (void)setUploadFilename:(NSString *)anUploadFilename
{
    [_uploadFilename release];
    _uploadFilename = [anUploadFilename retain];
}

- (NSString *)uploadSize
{
    return _uploadSize; 
}
- (void)setUploadSize:(NSString *)anUploadSize
{
    [_uploadSize release];
    _uploadSize = [anUploadSize retain];
}

-(void)dealloc
{
	[self setObjects:nil];
	[self setObjectsInfo:nil];
	[self setBucket:nil];

	[self setConnection:nil];
	[self setCurrentOperations:nil];

	[self setUploadKey:nil];
	[self setUploadACL:nil];
	[self setUploadFilename:nil];
	[self setCurrentOperations:nil];
	
	[super dealloc];
}

@end
