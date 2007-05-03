//
//  S3ObjectListController.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3ActiveWindowController.h"
#import "S3DragAndDropArrayController.h"

@class S3Bucket;


@interface S3ObjectListController : S3ActiveWindowController  <S3DragAndDropProtocol> {
	
	S3Bucket *_bucket;
	NSMutableArray *_objects;
	NSMutableDictionary *_objectsInfo;
	
	IBOutlet NSWindow *uploadSheet;
	IBOutlet NSWindow *multipleUploadSheet;
	IBOutlet S3DragAndDropArrayController *_objectsController;

	NSString *_uploadACL;
	NSString *_uploadFilename;
	NSString *_uploadSize;
	NSMutableArray *_uploadData;
    
    BOOL _needsRefresh;
}	

- (IBAction)refresh:(id)sender;
- (IBAction)upload:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)remove:(id)sender;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)closeSheet:(id)sender;

- (void)addObjects:(NSArray *)aObjects;

- (NSMutableArray *)objects;
- (void)setObjects:(NSMutableArray *)aObjects;

- (NSMutableDictionary *)objectsInfo;
- (void)setObjectsInfo:(NSMutableDictionary *)aObjectsInfo;

- (S3Bucket *)bucket;
- (void)setBucket:(S3Bucket *)aBucket;

- (NSString *)uploadACL;
- (void)setUploadACL:(NSString *)anUploadACL;
- (NSString *)uploadFilename;
- (void)setUploadFilename:(NSString *)anUploadFilename;
- (NSString *)uploadSize;
- (void)setUploadSize:(NSString *)anUploadSize;
- (NSMutableArray *)uploadData;
- (void)setUploadData:(NSMutableArray *)data;

@end
