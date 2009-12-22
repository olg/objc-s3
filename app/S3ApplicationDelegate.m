//
//  S3ApplicationDelegate.m
//  S3-Objc
//
//  Created by Michael Ledford on 9/11/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Security/Security.h>

#import "S3ApplicationDelegate.h"
#import "S3OperationLog.h"
#import "S3ConnectionInfo.h"
#import "S3LoginController.h"
#import "S3OperationQueue.h"
#import "S3OperationController.h"
#import "S3ValueTransformers.h"
#import "S3AppKitExtensions.h"
#import "S3BucketListController.h"

// C-string, as it is only used in Keychain Services
#define S3_BROWSER_KEYCHAIN_SERVICE "S3 Browser"

@implementation S3ApplicationDelegate

+ (void)initialize
{
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];

    NSMutableDictionary *userDefaultsValuesDict = [NSMutableDictionary dictionary];

    // Not setting a default value for this default, it should be nil if it doesn't exist.
    [userDefaultsValuesDict setObject:@"" forKey:@"defaultAccessKey"];
    [userDefaultsValuesDict setObject:[NSNumber numberWithBool:YES] forKey:@"autoclean"];
    [userDefaultsValuesDict setObject:[NSNumber numberWithBool:YES] forKey:@"consolevisible"];
    [userDefaultsValuesDict setObject:@"private" forKey:@"defaultUploadPrivacy"];
    [userDefaultsValuesDict setObject:[NSNumber numberWithBool:NO] forKey:@"useKeychain"];
    [userDefaultsValuesDict setObject:[NSNumber numberWithBool:YES] forKey:@"useSSL"];
    [userDefaultsValuesDict setObject:[NSNumber numberWithBool:NO] forKey:@"autologin"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];

    // Conversion code for new default
    NSString *defaultAccessKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"default-accesskey"];
    if (defaultAccessKey != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:defaultAccessKey forKey:@"defaultAccessKey"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"default-accesskey"];            
    }
    
    // Conversion code for new default
    NSString *defaultUploadPrivacyKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"default-upload-privacy"];
    if (defaultUploadPrivacyKey != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:defaultUploadPrivacyKey forKey:@"defaultUploadPrivacy"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"default-upload-privacy"];            
    }
    
    S3FileSizeTransformer *fileSizeTransformer = [[[S3FileSizeTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:fileSizeTransformer forName:@"S3FileSizeTransformer"];
}

- (id)init
{
    self = [super init];
    
    if (self != nil) {
        _controllers = [[NSMutableDictionary alloc] init];
        _queue = [[S3OperationQueue alloc] initWithDelegate:self];
        _operationLog = [[S3OperationLog alloc] init];
        _authenticationCredentials = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedLaunching) name:NSApplicationDidFinishLaunchingNotification object:NSApp];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:NSApp];

    [_queue release];
    [_operationLog release];
    [_controllers release];

    [super dealloc];
}

- (IBAction)openConnection:(id)sender
{    
	S3LoginController *c = [[[S3LoginController alloc] initWithWindowNibName:@"Authentication"] autorelease];

    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *useSSL = [standardUserDefaults objectForKey:@"useSSL"];
    
    S3ConnectionInfo *connectionInfo = [[S3ConnectionInfo alloc] initWithDelegate:self userInfo:nil secureConnection:[useSSL boolValue]];
    [c setConnectionInfo:connectionInfo];
    [connectionInfo release];        
	
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
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *useSSL = [standardUserDefaults objectForKey:@"useSSL"];
    
    S3ConnectionInfo *connectionInfo = [[S3ConnectionInfo alloc] initWithDelegate:self userInfo:nil secureConnection:[useSSL boolValue]];
    
    S3LoginController *c = [[[S3LoginController alloc] initWithWindowNibName:@"Authentication"] autorelease];
    [c setConnectionInfo:connectionInfo];
	
    [c showWindow:self];
    [c retain];
        
    [c connect:self];

    [connectionInfo release];
}

- (void)finishedLaunching
{
   
	S3OperationController *c = [[[S3OperationController alloc] initWithWindowNibName:@"Operations"] autorelease];
	[_controllers setObject:c forKey:@"Console"];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *consoleVisible = [standardUserDefaults objectForKey:@"consolevisible"];
    // cover the migration cases 
    if (([consoleVisible boolValue] == TRUE)||(consoleVisible==nil)) {
        [[_controllers objectForKey:@"Console"] showWindow:self];        
    } else {
        // Load the window to be ready for the console to be shown.
        [[_controllers objectForKey:@"Console"] window];
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

- (S3OperationLog *)operationLog
{
    return _operationLog;
}

- (void)setAuthenticationCredentials:(NSDictionary *)authDict forConnectionInfo:(S3ConnectionInfo *)connInfo
{
    if (authDict == nil || connInfo == nil) {
        return;
    }
    
    [_authenticationCredentials setObject:authDict forKey:connInfo];
}

- (void)removeAuthenticationCredentialsForConnectionInfo:(S3ConnectionInfo *)connInfo
{
    if (connInfo != nil) {
        [_authenticationCredentials removeObjectForKey:connInfo];
    }
}

- (NSDictionary *)authenticationCredentialsForConnectionInfo:(S3ConnectionInfo *)connInfo
{
    NSDictionary *dict = [_authenticationCredentials objectForKey:connInfo];
    if (dict != nil) {
        dict = [NSDictionary dictionaryWithDictionary:dict];
    }
    return dict;
}

#pragma mark S3ConnectionInfoDelegate Methods

- (NSString *)accessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo
{
    NSDictionary *authenticationCredentials = [self authenticationCredentialsForConnectionInfo:connectionInfo];
    if (authenticationCredentials == nil) {
        return nil;
    }

    // TODO: constant defined keys
    return [authenticationCredentials objectForKey:@"accessKey"];
}

- (NSString *)secretAccessKeyForConnectionInfo:(S3ConnectionInfo *)connectionInfo
{
    NSDictionary *authenticationCredentials = [self authenticationCredentialsForConnectionInfo:connectionInfo];
    if (authenticationCredentials == nil) {
        return nil;
    }
    
    // TODO: constant defined keys
    return [authenticationCredentials objectForKey:@"secretAccessKey"];
}

#pragma mark S3OperationQueueDelegate Methods

- (int)maximumNumberOfSimultaneousOperationsForOperationQueue:(S3OperationQueue *)operationQueue
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *maxOps = [standardUserDefaults objectForKey:@"maxoperations"];
    return [maxOps intValue];
}

@end
