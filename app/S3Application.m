//
//  S3Application.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Security/Security.h>

#import "S3ConnectionInfo.h"
#import "S3LoginController.h"
#import "S3OperationController.h"
#import "S3ValueTransformers.h"
#import "S3AppKitExtensions.h"
#import "S3BucketListController.h"

// C-string, as it is only used in Keychain Services
#define S3_BROWSER_KEYCHAIN_SERVICE "S3 Browser"

@interface S3Application (S3ApplicationPrivateAPI)
- (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;
- (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo;
@end

@implementation S3Application

+ (void)initialize {
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    
    S3FileSizeTransformer *fileSizeTransformer = [[[S3FileSizeTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:fileSizeTransformer forName:@"S3FileSizeTransformer"];
}

- (id)init
{
	[super init];
	_controlers = [[NSMutableDictionary alloc] init];
	_queue = [[S3OperationQueue alloc] init];
	return self;
}

- (IBAction)openConnection:(id)sender
{    
	S3LoginController *c = [[[S3LoginController alloc] initWithWindowNibName:@"Authentication"] autorelease];
//	[c setConnectionInfo:_connectionInfo];
	[c showWindow:self];
	[c retain];
}

- (IBAction)showOperationConsole:(id)sender
{
    // No-op, as everything is done in bindings
    // but we need a target/action for automatic enabling
}

- (void)tryAutoLogin
{
    NSString *defaultKey = [self accessKeyForConnectionInfo:_connectionInfo];
    NSString *accessKey = [self secretAccessKeyForConnectionInfo:_connectionInfo];
    if (defaultKey != nil && accessKey != nil)
    {
        S3BucketListController *c = [[[S3BucketListController alloc] initWithWindowNibName:@"Buckets"] autorelease];
        [c setConnectionInfo:_connectionInfo];
        [c showWindow:self];
        [c refresh:self];
        [c retain];			
    }    
}

- (void)¿
{
	[super finishLaunching];
    
    _connectionInfo = [[[S3ConnectionInfo alloc] init] autorelease];
    [_connectionInfo setDelegate:[NSApp delegate]];
    
	S3OperationController *c = [[[S3OperationController alloc] initWithWindowNibName:@"Operations"] autorelease];
	[_controlers setObject:c forKey:@"Console"];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *consoleVisible = [standardUserDefaults objectForKey:@"consolevisible"];
    // cover the migration cases 
    if (([consoleVisible boolValue] == TRUE)||(consoleVisible==nil)) {
        [[_controlers objectForKey:@"Console"] showWindow:self];        
    } else {
        // Load the window to be ready for the console to be shown.
        [[_controlers objectForKey:@"Console"] window];
    }
    
    if ([[standardUserDefaults objectForKey:@"autologin"] boolValue] == TRUE) {
        [self tryAutoLogin];
    }
}

- (IBAction)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://people.no-distance.net/ol/software/s3/"]];
}

- (S3OperationQueue *)queue
{
    return _queue;
}

#pragma mark S3ConnectionInfoDelegate Methods

- (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo
{
    NSString *defaultKey = nil;
    if (connectionInfo == _connectionInfo) {
        defaultKey = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER];        
    }
    return defaultKey;
}

- (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo
{
    NSString *accessKey = [self accessKeyForConnectionInfo:connectionInfo];

    if (accessKey == nil) {
        return nil;
    }

    void *passwordData = nil; // will be allocated and filled in by SecKeychainFindGenericPassword
	UInt32 passwordLength = 0;
    
	NSString *secretAccessKey = nil;
	const char *user = [accessKey UTF8String]; 
    
	OSStatus status;
	status = SecKeychainFindGenericPassword (NULL, // default keychain
                                             strlen(S3_BROWSER_KEYCHAIN_SERVICE), S3_BROWSER_KEYCHAIN_SERVICE,
                                             strlen(user), user,
                                             &passwordLength, &passwordData,
                                             nil);
	if (status == noErr) {
		secretAccessKey = [[[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding] autorelease];        
    }
	SecKeychainItemFreeContent(NULL, passwordData);	
	
	return secretAccessKey;
}

@end
