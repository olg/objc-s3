//
//  S3OperationQueue.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 04/02/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3OperationQueue.h"


@implementation S3OperationQueue

-(id)init
{
	[super init];
	_operations = [[NSMutableArray alloc] init];
	return self;
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

@end
