//
//  S3Owner.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 3/15/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface S3Owner : NSObject {
	NSString* _id;
	NSString* _displayName;
}

+ (S3Owner*)ownerWithXMLNode:(NSXMLElement*)element;

- (NSString *)ID;
- (void)setID:(NSString *)anId;
- (NSString *)displayName;
- (void)setDisplayName:(NSString *)aDisplayName;


@end
