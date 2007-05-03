//
//  S3ClickableURLField.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/8/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3ClickableURLField.h"


@implementation S3ClickableURLField

- (void)mouseDown:(NSEvent *)e
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self stringValue]]];
}

@end
