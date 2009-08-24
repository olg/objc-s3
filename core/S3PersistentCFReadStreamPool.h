//
//  S3PersistentCFReadStreamPool.h
//  S3-Objc
//
//  Created by Michael Ledford on 7/29/08.
//  Copyright 2008 Michael Ledford. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>

extern CFStringRef S3PersistentCFReadStreamPoolUniquePeropertyKey;

@interface S3PersistentCFReadStreamPool : NSObject {
    NSMutableDictionary *_activePersistentReadStreams;
    NSMutableArray *_overflow;
    NSTimer *_cleanPoolTimer;
}

+ (S3PersistentCFReadStreamPool *)sharedPersistentCFReadStreamPool;
+ (BOOL)sharedPersistentCFReadStreamPoolExists;

- (BOOL)addOpenedPersistentCFReadStream:(CFReadStreamRef)persistentCFReadStream inQueuePosition:(NSUInteger)position;
- (BOOL)addOpenedPersistentCFReadStream:(CFReadStreamRef)persistentCFReadStream;

- (void)removeOpenedPersistentCFReadStream:(CFReadStreamRef)readStream;

@end
