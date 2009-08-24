//
//  S3BucketListController.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "S3ActiveWindowController.h"

@class S3Connection;
@class S3Owner;

@interface S3BucketListController : S3ActiveWindowController {
    
    NSArray *_buckets;
    S3Owner *_bucketsOwner;
        
    IBOutlet NSArrayController *_bucketsController;

    IBOutlet NSWindow *addSheet;
    NSString *_name;
    BOOL _europe;
    
    NSMutableDictionary *_bucketListControllerCache;
}

- (IBAction)refresh:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)open:(id)sender;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)closeSheet:(id)sender;

- (NSString *)name;
- (void)setName:(NSString *)aName;

- (BOOL)isValidName;

- (S3Owner *)bucketsOwner;
- (void)setBucketsOwner:(S3Owner *)anBucketsOwner;

- (NSArray *)buckets;
- (void)setBuckets:(NSArray *)aBuckets;

@end
