//
//  S3Application.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Application.h"
#import "S3Connection.h"
#import "S3LoginController.h"
#import "S3OperationController.h"
#import "S3ValueTransformers.h"
#import "S3AppKitExtensions.h"
#import "S3BucketListController.h"

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
	S3Connection *cnx = [[[S3Connection alloc] init] autorelease];
	S3LoginController *c = [[[S3LoginController alloc] initWithWindowNibName:@"Authentication"] autorelease];
	[c setConnection:cnx];
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
    NSString* defaultKey = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER];
    if (defaultKey!=nil)
    {   
        S3Connection *cnx = [[[S3Connection alloc] init] autorelease];
        [cnx setAccessKeyID:defaultKey];
        [cnx trySetupSecretAccessKeyFromKeychain];
        if ([cnx isReady])
        {
            S3BucketListController *c = [[[S3BucketListController alloc] initWithWindowNibName:@"Buckets"] autorelease];
            [c setConnection:cnx];
            [c showWindow:self];
            [c refresh:self];
            [c retain];			
        }
    }    
}

- (void)finishLaunching
{
	[super finishLaunching];
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
    
    if ([[standardUserDefaults objectForKey:@"autologin"] boolValue] == TRUE)
        [self tryAutoLogin];
}

- (IBAction)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://people.no-distance.net/ol/software/s3/"]];
}

- (S3OperationQueue *)queue
{
    return _queue;
}

@end
