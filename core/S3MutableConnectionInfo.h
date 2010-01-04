//
//  S3MutableConnectionInfo.h
//  S3-Objc
//
//  Created by Michael Ledford on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3ConnectionInfo.h"

@interface S3MutableConnectionInfo : S3ConnectionInfo
@end

@interface S3MutableConnectionInfo (S3MutableConnectionInfoExtensionMethods)

// A delegate is required
- (void)setDelegate:(id)delegate;

// Sets userInfo that can be grabbed later. May 
// be nil. Especially useful for delegates
// who store a S3ConnectionInfo in certain
// collections since it effects (contributes to) equality.
- (void)setUserInfo:(NSDictionary *)userInfo;

// Insecure by default
// Resets the port number value to default
// for secure or insecure connection.
- (void)setSecureConnection:(BOOL)secure;

// Uses default port for either secure or
// insecure connection unless set after
// secure connection is set.
- (void)setPortNumber:(int)portNumber;

// Sets whether this connection should be
// vitually hosted or not. Defaults to YES.
- (void)setVirtuallyHosted:(BOOL)yesOrNo;

// If a host other than the default
// Amazon S3 host endpoint should be
// specified. Note, the only likely
// case for using this is using an
// Amazon S3 clone API.
// This is not to be used to make 
// virtually hosted buckets.
- (void)setHostEndpoint:(NSString *)host;

@end
