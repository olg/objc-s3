//
//  S3TransferRateCalculator.m
//  S3-Objc
//
//  Created by Michael Ledford on 3/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "S3TransferRateCalculator.h"

// Octet is the base unit
#define S3OctetUnitValue 1

// Units are expressed around base 2 values
// 1 Kibibit == 1024 bits == 128 Octets
#define S3KibibitUnitValue 128LL
#define S3MebibitUnitValue 131072LL
#define S3GibibitUnitValue 134217728LL
#define S3TebibitUnitValue 137438953472LL
#define S3PebibitUnitValue 140737488355328LL

// Units are expressed around base 10 values
// 1 Kilobit == 1000 bits == 125 Octets
#define S3KilobitUnitValue 125LL
#define S3MegabitUnitValue 125000LL
#define S3GigabitUnitValue 125000000LL
#define S3TerabitUnitValue 125000000000LL
#define S3PetabitUnitValue 125000000000000LL

// Units are expressed around base 2 values
// 1 Kibibyte == 1024 octets (bytes)
#define S3KibibyteUnitValue 1024LL
#define S3MebibyteUnitValue 1048576LL
#define S3GibibyteUnitValue 1073741824LL
#define S3TebibyteUnitValue 1099511627776LL
#define S3PebibyteUnitValue 1125899906842624LL

// Units are expressed around base 10 values
// 1 Kilobyte == 8000 bits
#define S3KilobyteUnitValue 1000LL
#define S3MegabyteUnitValue 1000000LL
#define S3GigabyteUnitValue 1000000000LL
#define S3TerabyteUnitValue 1000000000000LL
#define S3PetabyteUnitValue 1000000000000000LL

// Millisecond is the base unit
#define S3PerMillisecondRateValue 1
#define S3PerSecondRateValue      1000
#define S3PerMinuteRateValue      60000
#define S3PerHourRateValue        3600000
#define S3PerDayRateValue         86400000

@interface S3TransferRateCalculator (PrivateAPI)
- (void)resetTransferRateCalculator;
- (void)updateRateVariables:(NSTimer *)timer;
- (long long)valueForS3UnitType:(S3UnitType)unitType;
- (long long)valueForS3RateType:(S3RateType)rateType;
@end

@implementation S3TransferRateCalculator

+ (BOOL)accessInstanceVariablesDirectly
{
	return NO;
}

- (id)init
{
	[super init];
	_displayAverageRate = YES;
	_externalUnit = S3KibibyteUnit;
	_externalRate = S3PerSecondRate;
	_calculationRate = 1.0;
	_calculatedTransferRate = @"n/a";
	_timeRemaining = @"n/a";
	return self;
}

- (void)dealloc
{
	[self stopTransferRateCalculator];
	[_startTime release];
	[_lastUpdateTime release];
	[super dealloc];
}

- (S3UnitType)displayUnit
{
	return _externalUnit;
}

- (void)setDisplayUnit:(S3UnitType)displayUnit
{
	_externalUnit = displayUnit;
}

- (S3RateType)displayRate
{
	return _externalRate;
}

- (void)setDisplayRate:(S3RateType)displayRate
{
	_externalRate = displayRate;
}

- (void)setCalculateUsingAverageRate:(BOOL)yn
{
    _displayAverageRate = yn;
}

- (long long)valueForS3UnitType:(S3UnitType)unitType
{
	switch (unitType) {
		case S3OctetUnit:
			return S3OctetUnitValue;
			break;
        case S3KibibitUnit:
            return S3KibibitUnitValue;
            break;
        case S3MebibitUnit:
            return S3MebibitUnitValue;
            break;
        case S3GibibitUnit:
            return S3GibibitUnitValue;
            break;
        case S3TebibitUnit:
            return S3TebibitUnitValue;
            break;
        case S3PebibitUnit:
            return S3PebibitUnitValue;
            break;
        case S3KilobitUnit:
            return S3KilobitUnitValue;
            break;
        case S3MegabitUnit:
            return S3MegabitUnitValue;
            break;
        case S3GigabitUnit:
            return S3GigabitUnitValue;
            break;
        case S3TerabitUnit:
            return S3TerabitUnitValue;
            break;
        case S3PetabitUnit:
            return S3PetabitUnitValue;
            break;
		case S3KibibyteUnit:
			return S3KibibyteUnitValue;
			break;
		case S3MebibyteUnit:
			return S3MebibyteUnitValue;
			break;
		case S3GibibyteUnit:
			return S3GibibyteUnitValue;
			break;
		case S3TebibyteUnit:
			return S3TebibyteUnitValue;
			break;
		case S3PebibyteUnit:
			return S3PebibyteUnitValue;
			break;
		case S3KilobyteUnit:
			return S3KilobyteUnitValue;
			break;
		case S3MegabyteUnit:
			return S3MegabyteUnitValue;
			break;
		case S3GigabyteUnit:
			return S3GigabyteUnitValue;
			break;
		case S3TerabyteUnit:
			return S3TerabyteUnitValue;
			break;
		case S3PetabyteUnit:
			return S3PetabyteUnitValue;
			break;
		default:
			return 0;
	}
}

- (long long)valueForS3RateType:(S3RateType)rateType
{
	switch (rateType) {
		case S3PerMillisecondRate:
			return S3PerMillisecondRateValue;
			break;
		case S3PerSecondRate:
			return S3PerSecondRateValue;
			break;
		case S3PerMinuteRate:
			return S3PerMinuteRateValue;
			break;
		case S3PerHourRate:
			return S3PerHourRateValue;
			break;
		case S3PerDayRate:
			return S3PerDayRateValue;
			break;
		default:
			return 0;
	}
}

- (long long)objective
{
	return _objective;
}

- (BOOL)setObjective:(long long)bytes
{
    if ([self isRunning] == YES) {
        return NO;
    }
	if (bytes < 0) {
		_objective = 0;
		return NO;
	}
	_objective = bytes;
	return YES;
}

- (long long)totalTransfered
{
	return _totalTransfered;
}

- (BOOL)isRunning
{
	if (_calculateTimer == nil) {
		return NO;
	}
	return YES;
}

- (void)startTransferRateCalculator
{
    if ([self isRunning] == YES) {
        [self stopTransferRateCalculator];
        _totalTransfered = 0;
    }
	_calculateTimer = [NSTimer scheduledTimerWithTimeInterval:_calculationRate target:self selector:@selector(updateRateVariables:) userInfo:nil repeats:YES];
	[_calculateTimer retain];
	if (_startTime == nil) {
		_startTime = [[NSDate alloc] init];		
	}
}

- (void)stopTransferRateCalculator
{
	[_calculateTimer invalidate];
	[_calculateTimer release];
	_calculateTimer = nil;
	[_startTime release];
	_startTime = nil;
}

- (void)addBytesTransfered:(long long)bytes
{
	if ([self isRunning] == NO) {
		return;
	}
	long long left = LLONG_MAX - _totalTransfered;
	if (bytes < 0 || bytes > left) {
		// No room left
		return;
	}
	_pendingIncrease += bytes;
}

- (void)updateRateVariables:(NSTimer *)timer
{
	[_calculatedTransferRate release];
	_calculatedTransferRate = nil;
	if (_displayAverageRate == NO && _pendingIncrease > 0) {
		_calculatedTransferRate = [[NSString alloc] initWithFormat:@"%.2f", ((float)(_pendingIncrease) / [self valueForS3UnitType:_externalUnit]) / (([[NSDate date] timeIntervalSinceDate:_lastUpdateTime] * 1000.0) / [self valueForS3RateType:_externalRate])];
	}
	[_timeRemaining release];
	_timeRemaining = nil;
	if (_objective > 0 && _totalTransfered > 0) {
		// 
		NSTimeInterval estimatedSeconds = (_objective - _totalTransfered) / (_totalTransfered / [_lastUpdateTime timeIntervalSinceDate:_startTime]);
		int days = estimatedSeconds / 86400;
		estimatedSeconds = estimatedSeconds - (days * 86400);
		int hours = estimatedSeconds / 3600;
		estimatedSeconds = estimatedSeconds - (hours * 3600);
		int minutes = estimatedSeconds / 60;
		estimatedSeconds = estimatedSeconds - (minutes * 60);
		int seconds = estimatedSeconds - 0;
		NSMutableString *timeRemaining = [NSMutableString string];
		if (days > 0) {
			[timeRemaining appendFormat:@"%d ", days];
			if (days == 1) {
				[timeRemaining appendFormat:@"day"];
			} else {
				[timeRemaining appendFormat:@"days"];				
			}
            if (hours > 0 || minutes > 0 || seconds > 0) {
                [timeRemaining appendString:@" "];
            }
		}
        if (hours > 0) {
            if (hours < 10) {
                [timeRemaining appendFormat:@"%dh:", hours];                
            } else {
                [timeRemaining appendFormat:@"%.2dh:", hours];                
            }
        }
        if (hours > 0 || minutes > 0) {
            if (hours == 0 && minutes < 10) {
                [timeRemaining appendFormat:@"%dm:", minutes];                
            } else {
                [timeRemaining appendFormat:@"%.2dm:", minutes];                
            }
        }
        if (hours > 0 || minutes > 0 || seconds > 0) {
            if (hours == 0 && minutes == 0 && seconds < 10) {
                [timeRemaining appendFormat:@"%ds", seconds];                
            } else {
                [timeRemaining appendFormat:@"%.2ds", seconds];                
            }
        }
		_timeRemaining = [[NSString alloc] initWithString:timeRemaining];
	} else {
		_timeRemaining = [[NSString alloc] initWithString:@"n/a"];
	}	
	
	_totalTransfered += _pendingIncrease;
	_pendingIncrease = 0;
	[_lastUpdateTime autorelease];
	_lastUpdateTime = [[NSDate alloc] init];

	if (_displayAverageRate == YES && _totalTransfered > 0) {
		_calculatedTransferRate = [[NSString alloc] initWithFormat:@"%.2f", ((float)(_totalTransfered) / [self valueForS3UnitType:_externalUnit]) / (([_lastUpdateTime timeIntervalSinceDate:_startTime] * 1000.0) / [self valueForS3RateType:_externalRate])];
	}
}

- (NSString *)stringForCalculatedTransferRate
{
	return _calculatedTransferRate;
}

- (NSString *)stringForShortDisplayUnit
{
    switch (_externalUnit) {
		case S3OctetUnit:
			return @"oct";
			break;
        case S3KibibitUnit:
            return @"Kibit";
            break;
        case S3MebibitUnit:
            return @"Mibit";
            break;
        case S3GibibitUnit:
            return @"Gibit";
            break;
        case S3TebibitUnit:
            return @"Tibit";
            break;
        case S3PebibitUnit:
            return @"Pibit";
            break;
        case S3KilobitUnit:
            return @"kb";
            break;
        case S3MegabitUnit:
            return @"Mb";
            break;
        case S3GigabitUnit:
            return @"Gb";
            break;
        case S3TerabitUnit:
            return @"Tb";
            break;
        case S3PetabitUnit:
            return @"Pb";
            break;
		case S3KibibyteUnit:
			return @"KiB";
			break;
		case S3MebibyteUnit:
			return @"MiB";
			break;
		case S3GibibyteUnit:
			return @"GiB";
			break;
		case S3TebibyteUnit:
			return @"TiB";
			break;
		case S3PebibyteUnit:
			return @"PiB";
			break;
		case S3KilobyteUnit:
			return @"kB";
			break;
		case S3MegabyteUnit:
			return @"MB";
			break;
		case S3GigabyteUnit:
			return @"GB";
			break;
		case S3TerabyteUnit:
			return @"TB";
			break;
		case S3PetabyteUnit:
			return @"PB";
			break;
		default:
            return @"?";
	}
}

- (NSString *)stringForLongDisplayUnit
{
    switch (_externalUnit) {
		case S3OctetUnit:
			return @"octet";
			break;
        case S3KibibitUnit:
            return @"kibibit";
            break;
        case S3MebibitUnit:
            return @"Mebibit";
            break;
        case S3GibibitUnit:
            return @"Gibibit";
            break;
        case S3TebibitUnit:
            return @"Tebibit";
            break;
        case S3PebibitUnit:
            return @"Pebibit";
            break;
        case S3KilobitUnit:
            return @"kilobit";
            break;
        case S3MegabitUnit:
            return @"megabit";
            break;
        case S3GigabitUnit:
            return @"gigabit";
            break;
        case S3TerabitUnit:
            return @"terabit";
            break;
        case S3PetabitUnit:
            return @"petabit";
            break;            
		case S3KibibyteUnit:
			return @"kibibyte";
			break;
		case S3MebibyteUnit:
			return @"mebibyte";
			break;
		case S3GibibyteUnit:
			return @"gibibyte";
			break;
		case S3TebibyteUnit:
			return @"tebibyte";
			break;
		case S3PebibyteUnit:
			return @"pebibyte";
			break;
		case S3KilobyteUnit:
			return @"kilobyte";
			break;
		case S3MegabyteUnit:
			return @"megabyte";
			break;
		case S3GigabyteUnit:
			return @"gigabyte";
			break;
		case S3TerabyteUnit:
			return @"terabyte";
			break;
		case S3PetabyteUnit:
			return @"petabyte";
			break;
		default:
            return @"?";
	}
}

- (NSString *)stringForShortRateUnit
{
    switch (_externalRate) {
		case S3PerMillisecondRate:
			return @"ms";
			break;
		case S3PerSecondRate:
			return @"sec";
			break;
		case S3PerMinuteRate:
			return @"min";
			break;
		case S3PerHourRate:
			return @"hr";
			break;
		case S3PerDayRate:
			return @"d";
			break;
		default:
            return @"?";
	}    
}

- (NSString *)stringForLongRateUnit
{
    switch (_externalRate) {
		case S3PerMillisecondRate:
			return @"millisecond";
			break;
		case S3PerSecondRate:
			return @"second";
			break;
		case S3PerMinuteRate:
			return @"minute";
			break;
		case S3PerHourRate:
			return @"hour";
			break;
		case S3PerDayRate:
			return @"day";
			break;
		default:
            return @"?";
	}
}

- (NSString *)stringForEstimatedTimeRemaining
{
	return _timeRemaining;
}

- (NSString *)stringForObjectivePercentageCompleted
{
    if (_objective == 0) {
        return @"n/a";
    }
	return [NSString stringWithFormat:@"%.2f", ([self floatForObjectivePercentageCompleted]*100)];
}

- (float)floatForObjectivePercentageCompleted
{
	if (_totalTransfered == 0 || _objective == 0) {
		return 0.0;
	}
	return (_totalTransfered * 1.0) / _objective;
}

@end
