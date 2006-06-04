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

#import <Security/Security.h>

#define DEFAULT_USER @"default-accesskey"

// C-string, as it is only used in Keychain Services
#define S3_BROWSER_KEYCHAIN_SERVICE "S3 Browser"


@implementation S3LoginController

-(void)awakeFromNib
{
	[[self window] setDefaultButtonCell:[_defaultButton cell]];
	[[self window] setDelegate:self];
	[_connection addObserver:self
			  forKeyPath:@"accessKeyID" 
                 options:NSKeyValueObservingOptionNew
				 context:NULL];
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
	// Then only we observe is access key to check password in keychain
	[self checkPasswordInKeychain];
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
	if ([_keychainCheckbox state] == NSOnState)
		[self setS3KeyToKeychainForUser:[_connection accessKeyID] password:[_connection secretAccessKey]];
	
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

-(void)dealloc
{
	[self setOperation:nil];
	[self setConnection:nil];
	[super dealloc];
}

#pragma mark -
#pragma mark Keychain integration

-(void)checkPasswordInKeychain
{
	if ([_keychainCheckbox state] == NSOnState)
	{
		NSString* password = [self getS3KeyFromKeychainForUser:[_connection accessKeyID]];
		if (password!=nil)
			[_connection setSecretAccessKey:password];
	}
}

- (NSString*)getS3KeyFromKeychainForUser:(NSString *)username
{
	void *passwordData = nil; // will be allocated and filled in by SecKeychainFindGenericPassword
	UInt32 passwordLength = 0;

	NSString* password = nil;
	const char *user = [username UTF8String]; 

	OSStatus status;
	status = SecKeychainFindGenericPassword (NULL, // default keychain
                                             strlen(S3_BROWSER_KEYCHAIN_SERVICE), S3_BROWSER_KEYCHAIN_SERVICE,
                                             strlen(user), user,
                                             &passwordLength, &passwordData,
                                             nil);
	if (status==noErr)
		password = [[[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding] autorelease];
	SecKeychainItemFreeContent(NULL,passwordData);	
	
	return password;
}


- (BOOL)setS3KeyToKeychainForUser:(NSString *)username password:(NSString*)password
{
	const char *user = [username UTF8String]; 
	const char *pass = [password UTF8String]; 
	
	OSStatus status;
	status = SecKeychainAddGenericPassword(NULL, // default keychain
                                           strlen(S3_BROWSER_KEYCHAIN_SERVICE),S3_BROWSER_KEYCHAIN_SERVICE,
                                           strlen(user), user,
                                           strlen(pass), pass,
                                           nil);
	return (status==noErr);
}



@end
