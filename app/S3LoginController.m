//
//  S3LoginController.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/7/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Application.h"
#import "S3Connection.h"
#import "S3LoginController.h"
#import "S3BucketListController.h"
#import "S3BucketOperations.h"

#define DEFAULT_USER @"default-accesskey"

@implementation S3LoginController

-(void)awakeFromNib
{
	[[self window] setDefaultButtonCell:[_defaultButton cell]];
}

-(void)windowDidLoad
{
	NSString* defaultKey = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER];
	if (defaultKey!=nil)
		[_connection setAccessKeyID:defaultKey];
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

	[[NSUserDefaults standardUserDefaults] setObject:[_connection accessKeyID] forKey:DEFAULT_USER];
	
	S3BucketListController* c = [[[S3BucketListController alloc] initWithWindowNibName:@"Buckets"] autorelease];
	[c setConnection:_connection];
	[c showWindow:self];
	[c retain];			
	[c setBuckets:[(S3BucketListOperation*)o bucketList]];
	[c setBucketsOwner:[(S3BucketListOperation*)o owner]];	
	[self close];
}

#pragma mark -
#pragma mark Actions

-(IBAction)openHelpPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://aws.amazon.com/s3"]];
}

-(IBAction)connect:(id)sender
{
	S3BucketListOperation* op = [S3BucketListOperation bucketListOperationWithConnection:_connection delegate:self];
	[self setOperation:op];
	[(S3Application*)NSApp logOperation:op];
}

#pragma mark -
#pragma mark Key-value coding

- (S3Connection *)connection
{
    return _connection; 
}
- (void)setConnection:(S3Connection *)aConnection
{
    [_connection release];
    _connection = [aConnection retain];
}

- (S3Operation *)operation
{
    return _operation; 
}
- (void)setOperation:(S3Operation *)operation
{
    [_operation release];
    _operation = [operation retain];
}

@end
