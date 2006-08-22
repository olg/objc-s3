//
//  S3AppKitExtensions.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/11/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3AppKitExtensions.h"
#import "S3Extensions.h"

@implementation NSArrayController (ToolbarExtensions)

- (BOOL) validateToolbarItem:(NSToolbarItem*)theItem
{
	if ([theItem action] == @selector(remove:))
		return [self canRemove];
	else
		return TRUE;
}

@end


@implementation S3FileSizeTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)item {
    return [item readableFileSize];
}
@end