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


@implementation S3Application

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
	[[_controlers objectForKey:@"Console"] showWindow:self];
}

- (void)finishLaunching
{
	[super finishLaunching];
	S3OperationController* c = [[[S3OperationController alloc] initWithWindowNibName:@"Operations"] autorelease];
	[_controlers setObject:c forKey:@"Console"];
	[self showOperationConsole:self];
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

@end
