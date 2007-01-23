//
//  S3NSURLConnectionOperation.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 23/01/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"


@interface S3NSURLConnectionOperation : S3Operation {
	NSHTTPURLResponse* _response;
	NSURLRequest* _request;
	NSURLConnection* _connection;
	NSMutableData* _data;
}

-(id)initWithRequest:(NSURLRequest*)request delegate:(id)delegate;

@end
