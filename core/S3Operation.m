//
//  S3Operation.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/1/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import "S3Operation.h"

#import "S3Bucket.h"
#import "S3ConnectionInfo.h"
#import "S3PersistentCFReadStreamPool.h"
#import "S3HTTPUrlBuilder.h"
#import "S3TransferRateCalculator.h"


@interface S3Operation (S3OperationPrivateAPI)

- (void)handleNetworkEvent:(CFStreamEventType)eventType;

- (NSString *)protocolScheme;
- (int)portNumber;
- (NSString *)host;
- (NSString *)operationKey;

- (void)updateInformationalStatus;
- (void)updateInformationalSubStatus;

@end

#pragma mark -

#pragma mark Constants & Globals
static const CFOptionFlags S3OperationNetworkEvents =   kCFStreamEventOpenCompleted |
                                                        kCFStreamEventHasBytesAvailable |
                                                        kCFStreamEventEndEncountered |
                                                        kCFStreamEventErrorOccurred;

#pragma mark -

#pragma mark Static Functions
static void
ReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo) {
    // Pass off to the object to handle
    [((S3Operation *)clientCallBackInfo) handleNetworkEvent:type];
}

static void *myRetainCallback(void *info) {
    return (void *)[(NSObject *)info retain];
}

static void myReleaseCallback(void *info) {
    [(NSObject *)info release];
}


#pragma mark -

@implementation S3Operation

@synthesize delegate;
@synthesize allowsRetry;

@synthesize state;
@synthesize connectionInfo;
@synthesize informationalStatus;
@synthesize informationalSubStatus;

@synthesize requestHeaders;

@synthesize date = _date;
@synthesize responseHeaders;
@synthesize responseStatusCode;
@synthesize responseData;
@synthesize responseFileHandle;
@synthesize error;
@synthesize queuePosition;

@dynamic state;

+ (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObjects:@"state", nil] triggerChangeNotificationsForDependentKey:@"active"];
}

- (id)initWithConnectionInfo:(S3ConnectionInfo *)ci
{
    self = [super init];
    
    if (self != nil) {
        if (ci == nil) {
            [self release];
            return nil;
        }
        [self setConnectionInfo:ci];
        [self addObserver:self forKeyPath:@"informationalStatus" options:0 context:NULL];
        [self addObserver:self forKeyPath:@"informationalSubStatus" options:0 context:NULL];
    }
    
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"informationalStatus"];
    [self removeObserver:self forKeyPath:@"informationalSubStatus"];
    
    [connectionInfo release];
    [_date release];
    if (httpOperationReadStream != NULL) {
        CFRelease(httpOperationReadStream);        
    }
    [responseHeaders release];
    [responseData release];
    [responseFileHandle release];
    [informationalStatus release];
    [informationalSubStatus release];
    [rateCalculator release];
    [error release];

	[super dealloc];
}

- (S3OperationState)state
{
    return state;
}

- (void)setState:(S3OperationState)aState
{
    state = aState;
    [delegate operationStateDidChange:self];

    if (state == S3OperationPending) {
        [self setInformationalStatus:@"Pending"];
    } else if (state == S3OperationActive) {
        [self setInformationalStatus:@"Active"];
    } else if (state == S3OperationPendingRetry) {
        [self setInformationalStatus:@"Pending Retry"];
    } else if (state == S3OperationError) {
        [self setInformationalStatus:@"Error"];
    } else if (state == S3OperationCanceled) {
        [self setInformationalStatus:@"Canceled"];
    } else if (state == S3OperationDone) {
        [self setInformationalStatus:@"Done"];
    }
    [delegate operationInformationalStatusDidChange:self];
    
    [self setInformationalSubStatus:@""];
    [delegate operationInformationalSubStatusDidChange:self];
}

- (void)updateInformationalStatus
{
    
}

- (void)updateInformationalSubStatus
{
    NSMutableString *subStatus = [NSMutableString string];
    NSString *s = [rateCalculator stringForObjectivePercentageCompleted];
    if (s != nil) {
        [subStatus appendFormat:@"%@%% ",s];        
    }
    
    s = [rateCalculator stringForCalculatedTransferRate];
    if (s != nil) {
        [subStatus appendFormat:@"(%@ %@/%@) ", s, [rateCalculator stringForShortDisplayUnit], [rateCalculator stringForShortRateUnit]];        
    }
    
    s = [rateCalculator stringForEstimatedTimeRemaining];
    if (s != nil) {
        [subStatus appendString:s];        
    }
    [self setInformationalSubStatus:subStatus];
}

- (BOOL)active
{
    return ([self state] == S3OperationActive);
}

-(BOOL)success
{
    // TODO: Correct implementation
	return TRUE;
}

- (BOOL)isRequestOnService
{
    return (([self bucketName] == nil) && ([self key] == nil));
}

#pragma mark -
#pragma mark S3HTTPUrlBuilder Delegate Methods

- (NSString *)httpUrlBuilderWantsProtocolScheme:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self protocolScheme];
}

- (int)httpUrlBuilderWantsPort:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self portNumber];
}

- (NSString *)httpUrlBuilderWantsHost:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self host];
}

- (NSString *)httpUrlBuilderWantsKey:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self operationKey];
}

- (NSDictionary *)httpUrlBuilderWantsQueryItems:(S3HTTPURLBuilder *)httpUrlBuilder
{
    return [self requestQueryItems];
}

#pragma mark -
#pragma mark S3Operation Information Retrieval Methods

- (NSString *)protocolScheme
{
    if ([[self connectionInfo] secureConnection] == YES) {
        return @"https";
    }
    return @"http";
}

- (int)portNumber
{
    return [[self connectionInfo] portNumber];
}

- (NSString *)host
{
    if ([self isRequestOnService] == YES) {
        return [[self connectionInfo] hostEndpoint];
    } else if ([[self connectionInfo] virtuallyHosted] == YES && [self bucketName] != nil) {
        NSString *hostName = [NSString stringWithFormat:@"%@.%@", [self bucketName], [[self connectionInfo] hostEndpoint]];
        return hostName;
    }
    return [[self connectionInfo] hostEndpoint];
}

- (NSString *)operationKey
{
    if ([self isRequestOnService] == NO && [[self connectionInfo] virtuallyHosted] == NO && [self bucketName] != nil) {
        NSString *keyString = nil;
        if ([self key] != nil) {
            keyString = [NSString stringWithFormat:@"%@/%@", [self bucketName], [self key]];
        } else {
            keyString = [NSString stringWithFormat:@"%@/", [self bucketName]];
        }
        return keyString;
    }
    return [self key];
}

- (NSDictionary *)queryItems
{
    return nil;
}

- (NSString *)requestHTTPVerb
{
    return nil;
}

- (NSDictionary *)additionalHTTPRequestHeaders
{
    return nil;
}

- (NSString *)bucketName
{
    return nil;
}

- (NSString *)key
{
    return nil;
}

- (NSDictionary *)requestQueryItems
{
    return nil;
}

- (NSData *)requestBodyContentData
{
    return nil;
}

- (NSString *)requestBodyContentFilePath
{
    return nil;
}

- (NSString *)requestBodyContentMD5
{
    return nil;
}

- (NSString *)requestBodyContentType
{
    return nil;
}

- (NSUInteger)requestBodyContentLength
{
    return 0;
}

- (NSString *)responseBodyContentFilePath
{
    return nil;
}

- (long long)responseBodyContentExepctedLength
{
    return 0;
}

#pragma mark -

- (NSURL *)url
{    
    // Make Request String
    S3HTTPURLBuilder *urlBuilder = [[S3HTTPURLBuilder alloc] initWithDelegate:self];
    NSURL *builtURL = [urlBuilder url];
    [urlBuilder release];

    return builtURL;
}

-(void)stop:(id)sender
{	
    if ([self state] >= S3OperationCanceled || !(httpOperationReadStream)) {
        return;
    }
    
	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"This operation has been cancelled",NSLocalizedDescriptionKey,nil];
	[self setError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-1 userInfo:d]];
    
    CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
    CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    S3PersistentCFReadStreamPool *sharedPool = [S3PersistentCFReadStreamPool sharedPersistentCFReadStreamPool];
    [sharedPool removeOpenedPersistentCFReadStream:httpOperationReadStream];
    CFRelease(httpOperationReadStream);
    httpOperationReadStream = NULL;
    
    // Close filestream if available.
    [[self responseFileHandle] closeFile];
    
	[self setState:S3OperationCanceled];
    [rateCalculator stopTransferRateCalculator];    
}

- (void)start:(id)sender;
{
    if ([self responseBodyContentFilePath] != nil) {
        
        NSFileHandle *fileHandle = nil;
        BOOL fileCreated = [[NSFileManager defaultManager] createFileAtPath:[self responseBodyContentFilePath] contents:nil attributes:nil];
        
        if (fileCreated == YES) {
            fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self responseBodyContentFilePath]];
        } else {
            BOOL isDirectory = NO;
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self responseBodyContentFilePath] isDirectory:&isDirectory];
            if (fileExists == YES && isDirectory == NO) {
                if ([[NSFileManager defaultManager] isWritableFileAtPath:[self responseBodyContentFilePath]] == YES) {
                    fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self responseBodyContentFilePath]];
                }
            }
        }
                
        if (fileHandle == nil) {
            [self setState:S3OperationError];
            return;                
        }
        
        [self setResponseFileHandle:fileHandle];
    }
    
    NSCalendarDate *operationDate = [NSCalendarDate calendarDate];
    [operationDate setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [self setDate:operationDate];
    
    // Any headers or information to be included with this HTTP message should have happened before this point!
    
	CFHTTPMessageRef httpRequest = [connectionInfo createCFHTTPMessageRefFromOperation:self];
    if (httpRequest == NULL) {
        [self setState:S3OperationError];
        return;
    }
    
    NSInputStream *inputStream = nil;
    NSData *bodyContentsData = [self requestBodyContentData];
    NSString *bodyContentsFilePath = [self requestBodyContentFilePath];
    if (bodyContentsData != nil) {
        inputStream = [NSInputStream inputStreamWithData:bodyContentsData];
    } else if (bodyContentsFilePath != nil) {
        inputStream = [NSInputStream inputStreamWithFileAtPath:bodyContentsFilePath];
    }

    if (inputStream != nil) {
        httpOperationReadStream = CFReadStreamCreateForStreamedHTTPRequest(kCFAllocatorDefault, httpRequest, (CFReadStreamRef)inputStream);        
    } else {
        // If there is no body to send there is no need to make a streamed request.
        // When we are not doing a streamed request we can auto redirect!
        httpOperationReadStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, httpRequest);
        CFReadStreamSetProperty(httpOperationReadStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);
    }
    
    [self setRequestHeaders:[(NSDictionary *)CFHTTPMessageCopyAllHeaderFields(httpRequest) autorelease]];
    CFRelease(httpRequest);
    
    rateCalculator = [[S3TransferRateCalculator alloc] init];

    // Setup the rate calculator
    if (inputStream != nil) {
        // It is most likely upload data
        [rateCalculator setObjective:[self requestBodyContentLength]];
        // We need the rate calculator to ping us occasionally to update it.
        // To do this we set the rate calculator's delegate to us.
        [rateCalculator setDelegate:self];
    } else {
        // It is most likely download data
        [rateCalculator setObjective:[self responseBodyContentExepctedLength]];
    }
    
    
    // TODO: error checking on creation of read stream.
    
    CFReadStreamSetProperty(httpOperationReadStream, kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanTrue);
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(operationQueuePosition:)] == YES) {
        [self setQueuePosition:[[self delegate] operationQueuePosition:self]];
        NSNumber *queuePositionNumber = [[NSNumber alloc] initWithInteger:[self queuePosition]];
        CFReadStreamSetProperty(httpOperationReadStream, S3PersistentCFReadStreamPoolUniquePeropertyKey, (CFNumberRef)queuePositionNumber);
        [queuePositionNumber release];
    }
    
    // TODO: error checking on setting the stream client
    CFStreamClientContext clientContext = {0, self, NULL, NULL, NULL};
    CFReadStreamSetClient(httpOperationReadStream, S3OperationNetworkEvents, ReadStreamClientCallBack, &clientContext);
    
    // Schedule the stream
    CFReadStreamScheduleWithRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    if (!CFReadStreamOpen(httpOperationReadStream)) {
        CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        CFRelease(httpOperationReadStream);
        httpOperationReadStream = NULL;
        return;
    }
    [self setState:S3OperationActive];
}

- (void)handleStreamOpenCompleted
{
    
    // One should not close a stream once it is added to the S3PersistentCFReadStreamPool
    // S3PersistentCFReadStreamPool will take care of closing a stream so other persistent
    // streams can be enqueued on it.
    // If an error occurs or the stream has been canceled unregister the client and unschedule
    // from the run loop and ask the S3PersistentCFReadStreamPool to remove the stream.
    // Removing the stream will close the stream.
    S3PersistentCFReadStreamPool *sharedPool = [S3PersistentCFReadStreamPool sharedPersistentCFReadStreamPool];
    if ([sharedPool addOpenedPersistentCFReadStream:httpOperationReadStream inQueuePosition:[self queuePosition]] == NO) {
        CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        CFReadStreamClose(httpOperationReadStream);
        CFRelease(httpOperationReadStream);
        httpOperationReadStream = NULL;
        
        // Close filestream if available.
        [[self responseFileHandle] closeFile];
        
        [self setState:S3OperationError];
        return;
    }
        
    [rateCalculator startTransferRateCalculator];
}

- (void)handleStreamHavingBytesAvailable
{
    if (!httpOperationReadStream) {
        return;
    }
    
    UInt8 buffer[65536];
    CFIndex bytesRead = CFReadStreamRead(httpOperationReadStream, buffer, sizeof(buffer));
    if (bytesRead < 0) {
        // TODO: Something?
    } else if (bytesRead > 0) {
        if ([self responseFileHandle] != nil) {
            NSData *receivedData = [NSData dataWithBytesNoCopy:(void *)buffer length:bytesRead freeWhenDone:NO];
            [[self responseFileHandle] writeData:receivedData];
        } else {
            NSData *existingData = [self responseData];
            if (existingData == nil) {
                existingData = [NSData data];
                [self setResponseData:existingData];
            }
            NSMutableData *workingData = [NSMutableData dataWithData:existingData];
            [workingData appendBytes:(const void *)buffer length:bytesRead];
            [self setResponseData:workingData];            
        }
        [rateCalculator addBytesTransfered:bytesRead];
        [self updateInformationalSubStatus];
    }
}

- (void)handleStreamHavingEndEncountered
{
    CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
    CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    CFIndex statusCode = 0;
    
    // Copy out any headers
    CFHTTPMessageRef headerMessage = (CFHTTPMessageRef)CFReadStreamCopyProperty(httpOperationReadStream, kCFStreamPropertyHTTPResponseHeader);
    if (headerMessage != NULL) {
        // Get the HTTP status code
        statusCode = CFHTTPMessageGetResponseStatusCode(headerMessage);
        [self setResponseStatusCode:[NSNumber numberWithLong:statusCode]];
        
        NSDictionary *headerDict = (NSDictionary *)CFHTTPMessageCopyAllHeaderFields(headerMessage);
        if (headerDict != nil) {
            [self setResponseHeaders:headerDict];
            [headerDict release];
            headerDict = nil;
        }
        CFRelease(headerMessage);
        headerMessage = NULL;
    }
        
    if ([self didInterpretStateForStreamHavingEndEncountered] == NO) {
        if (statusCode >= 400) {
            [self setState:S3OperationError];
        } else if (statusCode >= 300 && statusCode < 400) {
            [self setState:S3OperationRequiresRedirect];
        } else {
            [self setState:S3OperationDone];            
        }
    }

    // Close filestream if available.
    [[self responseFileHandle] closeFile];

    [rateCalculator stopTransferRateCalculator];
    
    CFRelease(httpOperationReadStream);
    httpOperationReadStream = NULL;
}

- (void)handleStreamErrorOccurred
{
    CFReadStreamSetClient(httpOperationReadStream, 0, NULL, NULL);
    CFReadStreamUnscheduleFromRunLoop(httpOperationReadStream, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    S3PersistentCFReadStreamPool *sharedPool = [S3PersistentCFReadStreamPool sharedPersistentCFReadStreamPool];
    [sharedPool removeOpenedPersistentCFReadStream:httpOperationReadStream];
    CFRelease(httpOperationReadStream);
    httpOperationReadStream = NULL;
    
    // Close filestream if available.
    [[self responseFileHandle] closeFile];
    
    [self setState:S3OperationError];
    [rateCalculator stopTransferRateCalculator];
}

- (void)handleNetworkEvent:(CFStreamEventType)eventType
{
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
            [self handleStreamOpenCompleted];
            return;
            break;
            
        case kCFStreamEventHasBytesAvailable:
            [self handleStreamHavingBytesAvailable];
            return;
            break;
        
        case kCFStreamEventEndEncountered:
            [self handleStreamHavingEndEncountered];
            return;
            break;
            
        case kCFStreamEventErrorOccurred:
            [self handleStreamErrorOccurred];
            return;
            break;
            
        default:
            return;
            break;
    }
}

- (void)pingFromTransferRateCalculator:(S3TransferRateCalculator *)obj
{
    if (!httpOperationReadStream) {
        return;
    }
    NSData *bodyContentsData = [self requestBodyContentData];
    NSString *bodyContentsFilePath = [self requestBodyContentFilePath];
    if (bodyContentsData != nil || bodyContentsFilePath != nil) {
        // It is most likely upload data
        long long previouslyTransfered = [rateCalculator totalTransfered];
        NSNumber *totalTransferedNumber = (NSNumber *)CFReadStreamCopyProperty(httpOperationReadStream, kCFStreamPropertyHTTPRequestBytesWrittenCount);
        long long totalTransfered = [totalTransferedNumber longLongValue];
        [rateCalculator addBytesTransfered:(totalTransfered - previouslyTransfered)];
        [totalTransferedNumber release];
        [self updateInformationalSubStatus];
    }    
}

// Convenience method which setup an NSError from HTTP status and data by checking S3 error XML Documents
- (NSError*)errorFromHTTPRequestStatus:(int)status data:(NSData*)aData;
{
    NSError* aError = nil;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:[NSNumber numberWithInt:status] forKey:S3_ERROR_HTTP_STATUS_KEY];
    
    NSArray *a;
    NSXMLDocument *d = [[[NSXMLDocument alloc] initWithData:aData options:NSXMLDocumentTidyXML error:&error] autorelease];
    if (aError!=NULL)
        [dictionary setObject:aError forKey:NSUnderlyingErrorKey];
    
    a = [[d rootElement] nodesForXPath:@"//Code" error:&aError];
    if ([a count]==1) {
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:NSLocalizedDescriptionKey];
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:S3_ERROR_CODE_KEY];
    }
        
    a = [[d rootElement] nodesForXPath:@"//Message" error:&error];
    if (error!=NULL)
        [dictionary setObject:error forKey:NSUnderlyingErrorKey];
    if ([a count]==1)
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:NSLocalizedRecoverySuggestionErrorKey];
    
    a = [[d rootElement] nodesForXPath:@"//Resource" error:&error];
    if (error!=NULL)
        [dictionary setObject:error forKey:NSUnderlyingErrorKey];
    if ([a count]==1)
        [dictionary setObject:[[a objectAtIndex:0] stringValue] forKey:S3_ERROR_RESOURCE_KEY];
    
    return [NSError errorWithDomain:S3_ERROR_DOMAIN code:status userInfo:dictionary];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"informationalStatus"] == YES) {
        [delegate operationInformationalStatusDidChange:self];
    } else if ([keyPath isEqualToString:@"informationalSubStatus"] == YES) {
        [delegate operationInformationalSubStatusDidChange:self];
    }
}

- (BOOL)didInterpretStateForStreamHavingEndEncountered
{
    return NO;
}

@end
