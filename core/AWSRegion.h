//
//  AWSRegion.h
//  S3-Objc
//
//  Created by Michael Ledford on 12/28/09.
//  Copyright 2009 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *AWSRegionUSStandardKey;
extern NSString *AWSRegionUSWestKey;
extern NSString *AWSRegionUSEastKey;
extern NSString *AWSRegionEUIrelandKey;

typedef UInt32 AWSProductFlags;

// TODO: Support more of Amazon's Web Services
enum {
    AWSSimpleStorageService = (1L << 1)
//    AWSSimpleQueueService = (1L << 2),
//    AWSElasticComputeCloudService = (1L << 3),
//    AWSSimpleDBService = (1L << 4),
//    AWSCloudFrontService = (1L << 5),
//    AWSElasticMapReduceService = (1L << 6),
//    AWSImportExportService = (1L << 7),
//    AWSVirtualPrivateCloudService = (1L << 8),
//    AWSRelationalDatabaseService = (1L << 9),
};

@interface AWSRegion : NSObject <NSCopying> {
    NSString *regionKey;
    AWSProductFlags availableServices;
}

+ (NSArray *)availableAWSRegionKeys;
+ (id)regionWithKey:(NSString *)regionKey;

@property(readonly, nonatomic, copy) NSString *regionKey;
@property(readonly, nonatomic, copy) NSString *regionValue;
@property(readonly, nonatomic, assign) AWSProductFlags availableServices;

@end
