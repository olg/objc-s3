//
//  S3TransferRateCalculator.h
//  S3-Objc
//
//  Created by Michael Ledford on 3/14/07.
//  Copyright 2007 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _S3UnitType {
    // Base Unit 1 Octet / 8 Bits
    S3OctetUnit,
    // Base 2
    S3KibibitUnit,
    S3MebibitUnit,
    S3GibibitUnit,
    S3TebibitUnit,
    S3PebibitUnit,
    // Base 10
    S3KilobitUnit,
    S3MegabitUnit,
    S3GigabitUnit,
    S3TerabitUnit,
    S3PetabitUnit,
    // Base 2
    S3KibibyteUnit,
    S3MebibyteUnit,
    S3GibibyteUnit,
    S3TebibyteUnit,
    S3PebibyteUnit,
    S3ExbibyteUnit,
    // Base 10
    S3KilobyteUnit,
    S3MegabyteUnit,
    S3GigabyteUnit,
    S3TerabyteUnit,
    S3PetabyteUnit
} S3UnitType;

typedef enum _S3RateType {
    S3PerMillisecondRate,
    S3PerSecondRate,
    S3PerMinuteRate,
    S3PerHourRate,
    S3PerDayRate
} S3RateType;

@interface S3TransferRateCalculator : NSObject {
    id _delegate;
    
    S3UnitType _externalUnit;
    S3RateType _externalRate;

    long long _objective; // In bytes
    NSDate *_startTime;

    long long _totalTransfered; // In bytes
    long long _pendingIncrease; // In bytes

    NSDate *_lastUpdateTime;

    NSTimer *_calculateTimer;
    NSTimeInterval _calculationRate;
    
    NSString *_calculatedTransferRate;
    NSString *_timeRemaining;
    
    BOOL _displayAverageRate;
}

- (id)init;

- (id)delegate;
- (void)setDelegate:(id)object;

- (S3UnitType)displayUnit;
- (void)setDisplayUnit:(S3UnitType)displayUnit;

- (S3RateType)displayRate;
- (void)setDisplayRate:(S3RateType)displayRate;

- (void)setCalculateUsingAverageRate:(BOOL)yn;

- (long long)objective;
- (BOOL)setObjective:(long long)bytes;

- (long long)totalTransfered;

- (BOOL)isRunning;
- (void)startTransferRateCalculator;
- (void)stopTransferRateCalculator;

- (void)addBytesTransfered:(long long)bytes;

- (NSString *)stringForCalculatedTransferRate;
- (NSString *)stringForShortDisplayUnit;
- (NSString *)stringForLongDisplayUnit;
- (NSString *)stringForShortRateUnit;
- (NSString *)stringForLongRateUnit;
- (NSString *)stringForEstimatedTimeRemaining;
- (NSString *)stringForObjectivePercentageCompleted;
- (float)floatForObjectivePercentageCompleted; // 0.0 - 1.0

@end

@interface NSObject (S3TransferRateCalculatorDelegate)
- (void)pingFromTransferRateCalculator:(S3TransferRateCalculator *)obj;
@end