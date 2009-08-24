//
//  S3HTTPURLBuilder.h
//  S3-Objc
//
//  Created by Michael Ledford on 8/10/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// The goal of this class is to have a decoupled
// uniformed way to build up HTTP NSURL's for Amazon S3.
// To achive a dynamic decoupled object S3HTTPUrlBuilder
// uses only delegate methods to obtain the information
// needed.
//
// This class is not intended as a generic URI builder.
//
// Strings returned from delegate methods should not
// be encoded as the class will handle that detail for you.

@interface S3HTTPURLBuilder : NSObject {
    id delegate;
}

@property(nonatomic, assign, readwrite) id delegate;

- (id)initWithDelegate:(id)delegate;
- (NSURL *)url;

@end

@interface S3HTTPURLBuilder (S3HTTPUrlBuilderDelegateMethods)

- (NSString *)httpUrlBuilderWantsProtocolScheme:(S3HTTPURLBuilder *)urlBuilder;
- (NSString *)httpUrlBuilderWantsHost:(S3HTTPURLBuilder *)urlBuilder;
- (NSString *)httpUrlBuilderWantsKey:(S3HTTPURLBuilder *)urlBuilder; // Does not require '/' as its first char
- (NSDictionary *)httpUrlBuilderWantsQueryItems:(S3HTTPURLBuilder *)urlBuilder;
- (int)httpUrlBuilderWantsPort:(S3HTTPURLBuilder *)urlBuilder;

@end