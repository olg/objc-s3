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


@implementation NSHTTPURLResponse (Logging)

-(NSString*)httpStatus
{
	return [NSString stringWithFormat:@"%d (%@)",[self statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[self statusCode]]];
}

-(NSArray*)headersReceived
{
	NSMutableArray* a = [NSMutableArray array];
	NSEnumerator* e = [[self allHeaderFields] keyEnumerator];
	NSString* k;
	while (k = [e nextObject])
	{
		[a addObject:[NSDictionary dictionaryWithObjectsAndKeys:k,@"key",[[self allHeaderFields] objectForKey:k],@"value",nil]];
	}
	return a;
}

@end

@implementation NSURLRequest (Logging)

-(NSArray*)headersSent
{
	NSMutableArray* a = [NSMutableArray array];
	NSEnumerator* e = [[self allHTTPHeaderFields] keyEnumerator];
	NSString* k;
	while (k = [e nextObject])
	{
		[a addObject:[NSDictionary dictionaryWithObjectsAndKeys:k,@"key",[[self allHTTPHeaderFields] objectForKey:k],@"value",nil]];
	}
	return a;
}

@end



