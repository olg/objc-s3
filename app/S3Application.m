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

-(id)init
{
	[super init];
	_operations = [[NSMutableArray alloc] init];
	_controlers = [[NSMutableDictionary alloc] init];
	return self;
}

-(IBAction)openConnection:(id)sender
{
	S3Connection* cnx = [[[S3Connection alloc] init] autorelease];
	S3LoginController* c = [[[S3LoginController alloc] initWithWindowNibName:@"Authentication"] autorelease];
	[c setConnection:cnx];
	[c showWindow:self];
	[c retain];
}

-(IBAction)showOperationConsole:(id)sender
{
    // No-op, as everything is done in bindings
    // but we need a target/action for automatic enabling
}

- (void)tryAutoLogin
{
    NSString* defaultKey = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_USER];
    if (defaultKey!=nil)
    {   
        S3Connection* cnx = [[[S3Connection alloc] init] autorelease];
        [cnx setAccessKeyID:defaultKey];
        [cnx trySetupSecretAccessKeyFromKeychain];
        if ([cnx isReady])
        {
            S3BucketListController* c = [[[S3BucketListController alloc] initWithWindowNibName:@"Buckets"] autorelease];
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
	S3OperationController* c = [[[S3OperationController alloc] initWithWindowNibName:@"Operations"] autorelease];
	[_controlers setObject:c forKey:@"Console"];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber* consoleVisible = [standardUserDefaults objectForKey:@"consolevisible"];
    if (([consoleVisible boolValue] == TRUE)||(consoleVisible==nil)) // cover the migration cases 
        [[_controlers objectForKey:@"Console"] showWindow:self];
    
    if ([[standardUserDefaults objectForKey:@"autologin"] boolValue] == TRUE)
        [self tryAutoLogin];
}

-(IBAction)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://people.no-distance.net/ol/software/s3/"]];
}


#pragma mark -
#pragma mark Key-value coding

- (unsigned int)countOfOperations 
{
    return [_operations count];
}

- (id)objectInOperationsAtIndex:(unsigned int)index 
{
    return [_operations objectAtIndex:index];
}

- (void)insertObject:(id)anObject inOperationsAtIndex:(unsigned int)index 
{
    [_operations insertObject:anObject atIndex:index];
}

- (void)removeObjectFromOperationsAtIndex:(unsigned int)index 
{
    [_operations removeObjectAtIndex:index];
}

- (void)replaceObjectInOperationsAtIndex:(unsigned int)index withObject:(id)anObject 
{
    [_operations replaceObjectAtIndex:index withObject:anObject];
}


-(void)logOperation:(id)op
{
	[self insertObject:op inOperationsAtIndex:[self countOfOperations]];
}

-(void)unlogOperation:(id)op
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([[standardUserDefaults objectForKey:@"autoclean"] boolValue] == TRUE)
    {   
        unsigned i = [_operations indexOfObject:op];
        if (i != NSNotFound) {
            [[op retain] autorelease];
            [self removeObjectFromOperationsAtIndex:i];			
        }
    }
}

@end
