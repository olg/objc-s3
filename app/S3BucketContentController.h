//
//  S3BucketContentController.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "S3Operation.h"

@class S3Connection;
@class S3Bucket;

@interface S3BucketContentController : NSWindowController  <S3OperationDelegate> {
	S3Connection* _connection;
	NSMutableSet* _currentOperations;
	
	S3Bucket* _bucket;
	NSMutableArray* _objects;
	NSMutableDictionary* _objectsInfo;
	
	IBOutlet NSWindow* uploadSheet;
	IBOutlet NSArrayController* _objectsController;

	NSString* _uploadKey;
	NSString* _uploadACL;
	NSString* _uploadFilename;
	NSString* _uploadSize;
}	

- (IBAction)refresh:(id)sender;
- (IBAction)upload:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)remove:(id)sender;

-(IBAction)cancelSheet:(id)sender;
-(IBAction)closeSheet:(id)sender;


- (void)setConnection:(S3Connection *)aConnection;

- (NSMutableArray *)objects;
- (void)setObjects:(NSMutableArray *)aObjects;

- (NSMutableDictionary *)objectsInfo;
- (void)setObjectsInfo:(NSMutableDictionary *)aObjectsInfo;

- (S3Bucket *)bucket;
- (void)setBucket:(S3Bucket *)aBucket;

- (NSMutableSet *)currentOperations;
- (void)setCurrentOperations:(NSMutableSet *)aCurrentOperations;

- (NSString *)uploadKey;
- (void)setUploadKey:(NSString *)anUploadKey;
- (NSString *)uploadACL;
- (void)setUploadACL:(NSString *)anUploadACL;
- (NSString *)uploadFilename;
- (void)setUploadFilename:(NSString *)anUploadFilename;
- (NSString *)uploadSize;
- (void)setUploadSize:(NSString *)anUploadSize;

@end
