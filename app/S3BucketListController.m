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
#import "S3ObjectListController.h"
#import "S3Application.h"
#import "S3BucketListOperation.h"
#import "S3BucketAddOperation.h"
#import "S3BucketDeleteOperation.h"

#define SHEET_CANCEL 0
#define SHEET_OK 1



@implementation S3BucketListController

#pragma mark -
#pragma mark Toolbar management

-(void)awakeFromNib
{
    if ([S3ActiveWindowController instancesRespondToSelector:@selector(awakeFromNib)] == YES) {
        [super awakeFromNib];
    }
	NSToolbar* toolbar = [[[NSToolbar alloc] initWithIdentifier:@"BucketsToolbar"] autorelease];
	[toolbar setDelegate:self];
	[toolbar setVisible:YES];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setSizeMode:NSToolbarSizeModeDefault];
	[toolbar setDisplayMode:NSToolbarDisplayModeDefault];
	[[self window] setToolbar:toolbar];

	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
	[[[[[[self window] contentView] viewWithTag:10] tableColumnWithIdentifier:@"creationDate"] dataCell] setFormatter:dateFormatter];
    [[NSApp queue] addQueueListener:self];
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

-(void)s3OperationDidFinish:(NSNotification *)notification
{
    S3Operation *o = [[notification userInfo] objectForKey:S3OperationObjectKey];
    unsigned index = [_operations indexOfObjectIdenticalTo:o];
    if (index == NSNotFound) {
        return;
    }

    [super s3OperationDidFinish:notification];

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
	S3Bucket* b;
	NSEnumerator* e = [[_bucketsController selectedObjects] objectEnumerator];
	while (b = [e nextObject])
	{
		S3BucketDeleteOperation* op = [S3BucketDeleteOperation bucketDeletionWithConnection:_connection delegate:[NSApp queue] bucket:b];
		[self addToCurrentOperations:op];
	}
}

-(IBAction)refresh:(id)sender
{
	S3BucketListOperation* op = [S3BucketListOperation bucketListOperationWithConnection:_connection delegate:[NSApp queue]];
	[self addToCurrentOperations:op];
}


- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
	if (returnCode==SHEET_OK)
	{
		S3BucketAddOperation* op = [S3BucketAddOperation bucketAddWithConnection:_connection delegate:[NSApp queue] name:_name];
		[self addToCurrentOperations:op];
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
		S3ObjectListController* c = [[[S3ObjectListController alloc] initWithWindowNibName:@"Objects"] autorelease];
		[c setBucket:b];
		[c setConnection:_connection];
		[c showWindow:self];
		[c retain];
	}
}

#pragma mark -
#pragma mark Key-value coding

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"name",nil]
    triggerChangeNotificationsForDependentKey:@"isValidName"];
}

- (NSString *)name
{
    return _name; 
}
- (void)setName:(NSString *)aName
{
    [_name release];
    _name = [aName retain];
}

- (BOOL)isValidName
{
    // The length of the bucket name must be between 3 and 255 bytes. It can contain letters, numbers, dashes, and underscores.
    if ([_name length]<3)
        return NO;
    if ([_name length]>255)
        return NO;
    // This is a bit brute force, we should check iteratively and not reinstantiate on every call.
    NSCharacterSet* s = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-."] invertedSet];
    if ([_name rangeOfCharacterFromSet:s].location!=NSNotFound)
        return NO;
    return YES;
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

#pragma mark -
#pragma mark Dealloc

-(void)dealloc
{
    [[NSApp queue] removeQueueListener:self];

	[self setName:nil];
	[self setBucketsOwner:nil];
	[self setBuckets:nil];
	
	[super dealloc];
}

@end
