//
//  S3OperationLog.m
//  S3-Objc
//
//  Created by Michael Ledford on 12/1/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import "S3OperationLog.h"

#import "S3Operation.h"

@implementation S3OperationLog

@synthesize operations = _operations;

- (id)init
{
    self = [super init];
    
    if (self != nil) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [self setOperations:array];
        [array release];
    }
    
    return self;
}

- (void)insertObject:(id)object inOperationsAtIndex:(NSUInteger)index
{
    [[self operations] insertObject:object atIndex:index];
}

- (void)removeObjectFromOperationsAtIndex:(NSUInteger)index
{
    [[self operations] removeObjectAtIndex:index];
}

- (NSUInteger)countOfOperations
{
    return [[self operations] count];
}

- (void)logOperation:(S3Operation *)o
{
    [self insertObject:o inOperationsAtIndex:[self countOfOperations]];
}

- (void)unlogOperation:(S3Operation *)o
{
    // TODO: Move user defaults out of S3OperationQueue into a delegate method
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([[standardUserDefaults objectForKey:@"autoclean"] boolValue] == TRUE) {
        NSUInteger indexOfObject = [[self operations] indexOfObject:o];
        if (indexOfObject != NSNotFound) {
            [self removeObjectFromOperationsAtIndex:indexOfObject];            
        }
    }    
}

@end