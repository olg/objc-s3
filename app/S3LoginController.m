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
#import "S3BucketListOperation.h"
#import "S3OperationQueue.h"

@implementation S3LoginController

-(void)awakeFromNib
{
    if ([S3ActiveWindowController instancesRespondToSelector:@selector(awakeFromNib)] == YES) {
        [super awakeFromNib];
    }
	[[self window] setDefaultButtonCell:[_defaultButton cell]];
	[[self window] setDelegate:self];
	[_connection addObserver:self
			  forKeyPath:@"accessKeyID" 
                 options:NSKeyValueObservingOptionNew
				 context:NULL];
    [[NSApp queue] addQueueListener:self];
}

-(void)windowDidLoad
{
	NSString* defaultKey = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER];
	if (defaultKey!=nil)
	{
		[_connection setAccessKeyID:defaultKey];
		[self checkPasswordInKeychain];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[_connection removeObserver:self forKeyPath:@"accessID"];
}

- (IBAction)flippedKeychainSupport:(id)sender;
{
	[self checkPasswordInKeychain];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// The only thing we observe is access key to check password in keychain
	[self checkPasswordInKeychain];
}

-(void)s3OperationDidFinish:(NSNotification *)notification
{
    S3Operation *operation = [[notification userInfo] objectForKey:S3OperationObjectKey];
    unsigned index = [_operations indexOfObjectIdenticalTo:operation];
    if (index == NSNotFound) {
        return;
    }

    [super s3OperationDidFinish:notification];

	[[NSUserDefaults standardUserDefaults] setObject:[_connection accessKeyID] forKey:DEFAULT_USER];
	if ([_keychainCheckbox state] == NSOnState)
		[_connection storeSecretAccessKeyInKeychain];

	S3BucketListController* c = [[[S3BucketListController alloc] initWithWindowNibName:@"Buckets"] autorelease];
	[c setConnection:_connection];
	[c showWindow:self];
	[c retain];			
	[c setBuckets:[(S3BucketListOperation *)operation bucketList]];
	[c setBucketsOwner:[(S3BucketListOperation*)operation owner]];

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
	S3BucketListOperation* op = [S3BucketListOperation bucketListOperationWithConnection:_connection delegate:[NSApp queue]];
	[self addToCurrentOperations:op];
}

#pragma mark -
#pragma mark Keychain integration

-(void)checkPasswordInKeychain
{
	if ([_keychainCheckbox state] == NSOnState)
        [_connection trySetupSecretAccessKeyFromKeychain];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc
{
    [[NSApp queue] removeQueueListener:self];
    [super dealloc];
}

@end
