//
//  S3LoginController.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/7/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3ActiveWindowController.h"

@class S3Connection;

@interface S3LoginController : S3ActiveWindowController {
	IBOutlet NSButton* _defaultButton;
	IBOutlet NSButton* _keychainCheckbox;
}

- (IBAction)connect:(id)sender;
- (IBAction)openHelpPage:(id)sender;
- (IBAction)flippedKeychainSupport:(id)sender;

- (void)checkPasswordInKeychain;

- (NSString*)getS3KeyFromKeychainForUser:(NSString *)username;
- (BOOL)setS3KeyToKeychainForUser:(NSString *)username password:(NSString*)password;

@end
