//
//  AWSRegion.m
//  S3-Objc
//
//  Created by Michael Ledford on 12/28/09.
//  Copyright 2009 Michael Ledford. All rights reserved.
//

#import "AWSRegion.h"

NSString *AWSRegionUSStandardKey = @"AWSRegionUSStandardKey";
NSString *AWSRegionUSWestKey = @"AWSRegionUSWestKey";
NSString *AWSRegionUSEastKey = @"AWSRegionUSEastKey";
NSString *AWSRegionEUIrelandKey = @"AWSRegionEUIrelandKey";

NSString *AWSRegionUSStandardValue = @"";
NSString *AWSRegionUSWestValue = @"us-west-1";
NSString *AWSRegionUSEastValue = @"us-east-1";
NSString *AWSRegionEUIrelandValue = @"EU";


@interface AWSRegion ()
@property(readwrite, nonatomic, copy) NSString *regionKey;
@property(readwrite, nonatomic, copy) NSString *regionValue;
@property(readwrite, nonatomic, assign) AWSProductFlags availableServices;
@end


@implementation AWSRegion

@synthesize regionKey;
@dynamic regionValue;
@synthesize availableServices;

// TODO: flyweight pattern the results

+ (NSDictionary *)availableAWSRegionKeysAndValues
{
    return [NSDictionary dictionaryWithObjectsAndKeys:AWSRegionUSStandardValue, AWSRegionUSStandardKey,
                                                      AWSRegionUSWestValue, AWSRegionUSWestKey,
                                                      AWSRegionUSEastValue, AWSRegionUSEastKey,
                                                      AWSRegionEUIrelandValue, AWSRegionEUIrelandKey,
                                                      nil];
}

+ (NSArray *)availableAWSRegionKeys
{
    NSDictionary *availableKeysAndValues = [[self class] availableAWSRegionKeysAndValues];
    return [availableKeysAndValues allKeys];
}

+ (id)regionWithKey:(NSString *)theRegionKey
{
    NSArray *regionKeys = [self availableAWSRegionKeys];
    for (NSString *availableKey in regionKeys) {
        if ([theRegionKey isEqualToString:availableKey]) {
            AWSRegion *region = [[AWSRegion alloc] init];
            [region setRegionKey:theRegionKey];
            // TODO: a better way to set the available services for each region
            if (![theRegionKey isEqualToString:AWSRegionUSEastKey]) {
                [region setAvailableServices:AWSSimpleStorageService];                
            }
            return [region autorelease];
        }
    }
    return nil;
}

- (NSString *)regionValue
{
    return [[[self class] availableAWSRegionKeysAndValues] objectForKey:[self regionKey]];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self retain];
}

@end
