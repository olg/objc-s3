//
//  S3LoginController.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/7/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ApplicationDelegate.h"
#import "S3LoginController.h"
#import "S3BucketListController.h"
#import "S3ListBucketOperation.h"
#import "S3OperationQueue.h"

// C-string, as it is only used in Keychain Services
#define S3_BROWSER_KEYCHAIN_SERVICE "S3 Browser"


@interface S3LoginController ()

- (NSString *)getS3SecretKeyFromKeychainForS3AccessKey:(NSString *)accesskey;
- (BOOL)setS3SecretKeyToKeychainForS3AccessKey:(NSString *)accesskey password:(NSString *)secretkey;
- (void)checkPasswordInKeychain;

@end

@implementation S3LoginController

#pragma mark -
#pragma mark Dealloc

- (void)dealloc
{
    [[[NSApp delegate] queue] removeQueueListener:self];
    [super dealloc];
}

#pragma mark -
#pragma mark General Methods

- (void)awakeFromNib
{
    if ([S3ActiveWindowController instancesRespondToSelector:@selector(awakeFromNib)] == YES) {
        [super awakeFromNib];
    }
	[[self window] setDefaultButtonCell:[_defaultButton cell]];
	[[self window] setDelegate:self];
    [[[NSApp delegate] queue] addQueueListener:self];
}

- (void)windowDidLoad
{
	NSString *defaultKey = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER];
	if (defaultKey != nil) {
		[self checkPasswordInKeychain];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
//	[_connection removeObserver:self forKeyPath:@"accessID"];
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

- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
{
    S3Operation *operation = [[notification userInfo] objectForKey:S3OperationObjectKey];
    unsigned index = [_operations indexOfObjectIdenticalTo:operation];
    if (index == NSNotFound) {
        return;
    }

    [super operationQueueOperationStateDidChange:notification];

    if ([operation state] == S3OperationDone) {

        if ([_keychainCheckbox state] == NSOnState) {
            [self setS3SecretKeyToKeychainForS3AccessKey:accessKeyID password:secretAccessKeyID];
        }
        
        S3BucketListController *c = [[[S3BucketListController alloc] initWithWindowNibName:@"Buckets"] autorelease];
        
        [c setConnectionInfo:[self connectionInfo]];
        
        [c showWindow:self];
        [c retain];			
        [c setBuckets:[(S3ListBucketOperation *)operation bucketList]];
        [c setBucketsOwner:[(S3ListBucketOperation*)operation owner]];

        [self close];
    }
}

#pragma mark -
#pragma mark Actions

- (IBAction)connect:(id)sender
{
    if (accessKeyID == nil && secretAccessKeyID == nil) {
        return;
    }
    [accessKeyID release];
    accessKeyID = [[[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER] retain];
    
    NSDictionary *authDict = [NSDictionary dictionaryWithObjectsAndKeys:accessKeyID, @"accessKey", secretAccessKeyID, @"secretAccessKey", nil]; 
    
    [[NSApp delegate] setAuthenticationCredentials:authDict forConnectionInfo:[self connectionInfo]];
    
	S3ListBucketOperation *op = [[S3ListBucketOperation alloc] initWithConnectionInfo:[self connectionInfo]];

    [self addToCurrentOperations:op];
}

- (IBAction)openHelpPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://aws.amazon.com/s3"]];
}

#pragma mark -
#pragma mark Keychain integration

- (NSString *)getS3SecretKeyFromKeychainForS3AccessKey:(NSString *)accesskey
{
    if ([accesskey length] == 0) {
        return nil;
    }
    
    void *secretData = nil; // will be allocated and filled in by SecKeychainFindGenericPassword
    UInt32 secretLength = 0;
    
    NSString *secret = @"";
    const char *key = [accesskey UTF8String]; 
    
    OSStatus status;
    status = SecKeychainFindGenericPassword (NULL, // default keychain
                                             strlen(S3_BROWSER_KEYCHAIN_SERVICE), S3_BROWSER_KEYCHAIN_SERVICE,
                                             strlen(key), key,
                                             &secretLength, &secretData,
                                             nil);
    if (status==noErr) {
        secret = [[[NSString alloc] initWithBytes:secretData length:secretLength encoding:NSUTF8StringEncoding] autorelease];        
    }
    
    SecKeychainItemFreeContent(NULL,secretData);	
    
    return secret;
}


- (BOOL)setS3SecretKeyToKeychainForS3AccessKey:(NSString *)accesskey password:(NSString *)secretkey
{
    const char *key = [accesskey UTF8String]; 
    const char *secret = [secretkey UTF8String]; 
    
    OSStatus status;
    status = SecKeychainAddGenericPassword(NULL, // default keychain
                                           strlen(S3_BROWSER_KEYCHAIN_SERVICE),S3_BROWSER_KEYCHAIN_SERVICE,
                                           strlen(key), key,
                                           strlen(secret), secret,
                                           nil);
    return (status==noErr);
}

- (void)checkPasswordInKeychain
{
	if ([_keychainCheckbox state] == NSOnState) {
        [self setValue:[self getS3SecretKeyFromKeychainForS3AccessKey:[[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER]] forKey:@"secretAccessKeyID"];
    }
}
@end
