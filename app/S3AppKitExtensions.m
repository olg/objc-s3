//
//  S3AppKitExtensions.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/11/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3AppKitExtensions.h"

@implementation NSArrayController (ToolbarExtensions)

- (BOOL) validateToolbarItem:(NSToolbarItem*)theItem
{
	if ([theItem action] == @selector(remove:))
		return [self canRemove];
	else
		return TRUE;
}

@end