//
//  S3ObjectListController.m
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/3/06.
//  Copyright 2006 Olivier Gutknecht. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>

#import "S3ObjectListController.h"
#import "S3Extensions.h"
#import "S3ConnectionInfo.h"
#import "S3MutableConnectionInfo.h"
#import "S3Bucket.h"
#import "S3Object.h"
#import "S3ApplicationDelegate.h"
#import "S3DownloadObjectOperation.h"
#import "S3AddObjectOperation.h"
#import "S3ListObjectOperation.h"
#import "S3DeleteObjectOperation.h"
#import "S3CopyObjectOperation.h"
#import "S3OperationQueue.h"
#import "S3Extensions.h"

#define SHEET_CANCEL 0
#define SHEET_OK 1

#define DEFAULT_PRIVACY @"defaultUploadPrivacy"
#define ACL_PRIVATE @"private"

#define FILEDATA_PATH @"path"
#define FILEDATA_KEY  @"key"
#define FILEDATA_TYPE @"mime"
#define FILEDATA_SIZE @"size"

@implementation S3ObjectListController

#pragma mark -
#pragma mark Toolbar management

+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObjects:@"validList", nil] triggerChangeNotificationsForDependentKey:@"validListString"];
}

- (void)awakeFromNib
{
    if ([S3ActiveWindowController instancesRespondToSelector:@selector(awakeFromNib)] == YES) {
        [super awakeFromNib];
    }
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"ObjectsToolbar"] autorelease];
    [toolbar setDelegate:self];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setSizeMode:NSToolbarSizeModeDefault];
    [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
    [[self window] setToolbar:toolbar];

    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
    [[[[[[self window] contentView] viewWithTag:10] tableColumnWithIdentifier:@"lastModified"] dataCell] setFormatter:dateFormatter];

    _renameOperations = [[NSMutableArray alloc] init];
    _redirectConnectionInfoMappings = [[NSMutableDictionary alloc] init];
    
    [_objectsController setFileOperationsDelegate:self];
    
    [[[NSApp delegate] queue] addQueueListener:self];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects: NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        @"Refresh", @"Upload", @"Download", @"Remove", @"Remove All", @"Rename", nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if ([[theItem itemIdentifier] isEqualToString: @"Remove All"]) {
        return [[_objectsController arrangedObjects] count] > 0;
    } else if ([[theItem itemIdentifier] isEqualToString: @"Remove"]) {
        return [_objectsController canRemove];        
    } else if ([[theItem itemIdentifier] isEqualToString: @"Download"]) {
        return [_objectsController canRemove];        
    } else if ([[theItem itemIdentifier] isEqualToString: @"Rename"]) {
        return ([[_objectsController selectedObjects] count] == 1 );
    }
    return YES;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects: @"Upload", @"Download", @"Rename", @"Remove", NSToolbarSeparatorItemIdentifier,  @"Remove All", NSToolbarFlexibleSpaceItemIdentifier, @"Refresh", nil]; 
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL) flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
    
    if ([itemIdentifier isEqualToString: @"Upload"])
    {
        [item setLabel: NSLocalizedString(@"Upload", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"upload.icns"]];
        [item setTarget:self];
        [item setAction:@selector(upload:)];
    }
    if ([itemIdentifier isEqualToString: @"Download"])
    {
        [item setLabel: NSLocalizedString(@"Download", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"download.icns"]];
        [item setTarget:self];
        [item setAction:@selector(download:)];
    }
    else if ([itemIdentifier isEqualToString: @"Remove"])
    {
        [item setLabel: NSLocalizedString(@"Remove", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"delete.icns"]];
        [item setTarget:self];
        [item setAction:@selector(remove:)];
    }
    else if ([itemIdentifier isEqualToString: @"Remove All"])
    {
        [item setLabel: NSLocalizedString(@"Remove All", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"delete.icns"]];
        [item setTarget:self];
        [item setAction:@selector(removeAll:)];
    }
    else if ([itemIdentifier isEqualToString: @"Refresh"])
    {
        [item setLabel: NSLocalizedString(@"Refresh", nil)];
        [item setPaletteLabel: [item label]];
        [item setImage: [NSImage imageNamed: @"refresh.icns"]];
        [item setTarget:self];
        [item setAction:@selector(refresh:)];
    } else if ([itemIdentifier isEqualToString:@"Rename"]) {
        [item setLabel:NSLocalizedString(@"Rename", nil)];
        [item setPaletteLabel: [item label]];
//        [item setImage: [NSImage imageNamed: @"refresh.icns"]]
        [item setTarget:self];
        [item setAction:@selector(rename:)];
    }
    
    return [item autorelease];
}


#pragma mark -
#pragma mark Misc Delegates


- (void)windowDidLoad
{
    [self refresh:self];
}

- (IBAction)cancelSheet:(id)sender
{
    [NSApp endSheet:[sender window] returnCode:SHEET_CANCEL];
}

- (IBAction)closeSheet:(id)sender
{
    [NSApp endSheet:[sender window] returnCode:SHEET_OK];
}

- (void)operationQueueOperationStateDidChange:(NSNotification *)notification
{
    S3Operation *op = [[notification userInfo] objectForKey:S3OperationObjectKey];
    unsigned index = [_operations indexOfObjectIdenticalTo:op];
    if (index == NSNotFound) {
        return;
    }
    
    [super operationQueueOperationStateDidChange:notification];
        
    if ([op isKindOfClass:[S3ListObjectOperation class]] && [op state] == S3OperationDone) {
        [self addObjects:[(S3ListObjectOperation *)op objects]];
        [self setObjectsInfo:[(S3ListObjectOperation*)op metadata]];
        
        S3ListObjectOperation *next = [(S3ListObjectOperation *)op operationForNextChunk];
        if (next != nil) {
            [self addToCurrentOperations:next];            
        } else {
            [self setValidList:YES];
        }
    }
    
    if ([op isKindOfClass:[S3CopyObjectOperation class]] && [_renameOperations containsObject:op] && [op state] == S3OperationDone) {
        [self setValidList:NO];
        S3Object *sourceObject = [[op operationInfo] objectForKey:@"sourceObject"];
        S3DeleteObjectOperation *deleteOp = [[S3DeleteObjectOperation alloc] initWithConnectionInfo:[op connectionInfo] object:sourceObject];
        [_renameOperations removeObject:op];
        [self addToCurrentOperations:deleteOp];
        [deleteOp release];
    }
    
    if (([op isKindOfClass:[S3AddObjectOperation class]] || [op isKindOfClass:[S3DeleteObjectOperation class]]) && [op state] == S3OperationDone) {
        [self setValidList:NO];
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if ([[standardUserDefaults objectForKey:@"norefresh"] boolValue] == TRUE) {
            return;
        }
        // Simple heuristics: if we still have something in the operation queue, no need to refresh now
        if (![self hasActiveOperations]) {
            [self refresh:self];            
        } else {
            _needsRefresh = YES;
        }
    }
}

//- (void)s3OperationDidFail:(NSNotification *)notification
//{
//    S3Operation *op = [[notification userInfo] objectForKey:S3OperationObjectKey];
//    unsigned index = [_operations indexOfObjectIdenticalTo:op];
//    if (index == NSNotFound) {
//        return;
//    }
//    
//    [super s3OperationDidFail:notification];
//    
//    if (_needsRefresh == YES && [self hasActiveOperations] == NO) {
//        [self refresh:self];
//    }
//}

#pragma mark -
#pragma mark Actions

- (IBAction)refresh:(id)sender
{
    [self setObjects:[NSMutableArray array]];
    [self setValidList:NO];
        
    S3ListObjectOperation *op = [[S3ListObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] bucket:[self bucket]];
    
    [self addToCurrentOperations:op];
}

-(IBAction)removeAll:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Remove all objects permanently?",nil)];
    [alert setInformativeText:NSLocalizedString(@"Warning: Are you sure you want to remove all objects in this bucket? This operation cannot be undone.",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Remove",nil)];
    if ([alert runModal] == NSAlertFirstButtonReturn)
    {
        [alert release];
        return;
    }
    [alert release];
    
    S3Object *b;
    NSEnumerator *e = [[_objectsController arrangedObjects] objectEnumerator];
        
    while (b = [e nextObject])
    {
        S3DeleteObjectOperation *op = [[S3DeleteObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] object:b];
        [self addToCurrentOperations:op];
        [op release];
    }
}

- (IBAction)remove:(id)sender
{
    S3Object *b;
    int count = [[_objectsController selectedObjects] count];

    if (count>=10)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Remove %d objects permanently?",nil), count]];
        [alert setInformativeText:NSLocalizedString(@"Warning: Are you sure you want to remove these objects from this bucket? This operation cannot be undone.",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Remove",nil)];
        if ([alert runModal] == NSAlertFirstButtonReturn)
        {
            [alert release];
            return;
        }
        [alert release];        
    }
    
    NSEnumerator *e = [[_objectsController selectedObjects] objectEnumerator];
    while (b = [e nextObject])
    {
        S3DeleteObjectOperation *op = [[S3DeleteObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] object:b];
        [self addToCurrentOperations:op];
        [op release];
    }
}

- (IBAction)download:(id)sender
{
    S3Object *b;
    NSEnumerator *e = [[_objectsController selectedObjects] objectEnumerator];
        
    while (b = [e nextObject])
    {
        NSSavePanel *sp = [NSSavePanel savePanel];
        int runResult;
        NSString *n = [[b key] lastPathComponent];
        if (n==nil) n = @"Untitled";
        runResult = [sp runModalForDirectory:nil file:n];
        if (runResult == NSOKButton) {
            S3DownloadObjectOperation *op = [[S3DownloadObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] object:b saveTo:[sp filename]];
            [self addToCurrentOperations:op];
            [op release];
        }
    }
}


- (void)uploadFile:(NSDictionary *)data acl:(NSString *)acl
{
    NSString *path = [data objectForKey:FILEDATA_PATH];
    NSString *key = [data objectForKey:FILEDATA_KEY];
    NSString *mime = [data objectForKey:FILEDATA_TYPE];
    NSNumber *size = [data objectForKey:FILEDATA_SIZE];
    
    if (![self acceptFileForImport:path])
    {   
        NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"The file '%@' could not be read",nil),path],NSLocalizedDescriptionKey,nil];
        [[self window] presentError:[NSError errorWithDomain:S3_ERROR_DOMAIN code:-2 userInfo:d] modalForWindow:[self window] delegate:self 
                 didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:nil];
        return;        
    }
    
    NSMutableDictionary *dataSourceInfo = nil;
    NSString *md5 = nil;
    if ([size longLongValue] < (1024 * 16)) {
        NSData *bodyData = [NSData dataWithContentsOfFile:path];
        dataSourceInfo = [NSDictionary dictionaryWithObject:bodyData forKey:S3ObjectNSDataSourceKey];        
        md5 = [[bodyData md5Digest] encodeBase64];
    } else {
        dataSourceInfo = [NSDictionary dictionaryWithObject:path forKey:S3ObjectFilePathDataSourceKey];        
        NSError *error = nil;
        NSData *bodyData = [NSData dataWithContentsOfFile:path options:(NSMappedRead|NSUncachedRead) error:&error];
        md5 = [[bodyData md5Digest] encodeBase64];
    }
    
    NSMutableDictionary *metadataDict = [NSMutableDictionary dictionary];
    if (md5 != nil) {
        [metadataDict setObject:md5 forKey:S3ObjectMetadataContentMD5Key];
    }
    if (mime != nil) {
        [metadataDict setObject:mime forKey:S3ObjectMetadataContentTypeKey];
    }
    if (acl != nil) {
        [metadataDict setObject:acl forKey:S3ObjectMetadataACLKey];
    }
    if (size != nil) {
        [metadataDict setObject:size forKey:S3ObjectMetadataContentLengthKey];
    }
    S3Object *objectToAdd = [[S3Object alloc] initWithBucket:[self bucket] key:key userDefinedMetadata:nil metadata:metadataDict dataSourceInfo:dataSourceInfo];
        
    S3AddObjectOperation *op = [[S3AddObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] object:objectToAdd];
    [objectToAdd release];

    [self addToCurrentOperations:op];
    [op release];
}

- (void)uploadFiles
{	
    NSEnumerator *e = [[self uploadData] objectEnumerator];
    NSDictionary *data;

    while (data = [e nextObject]) {
        [self uploadFile:data acl:[self uploadACL]];        
    }
}

- (IBAction)upload:(id)sender
{
    NSOpenPanel *oPanel = [[NSOpenPanel openPanel] retain];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setPrompt:NSLocalizedString(@"Upload",nil)];
    [oPanel setCanChooseDirectories:TRUE];
    [oPanel beginForDirectory:nil file:nil types:nil modelessDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    if (returnCode!=SHEET_OK)
        return;
    
    [self uploadFiles];
}

- (BOOL)acceptFileForImport:(NSString *)path
{
    return [[NSFileManager defaultManager] isReadableFileAtPath:path];
}

- (void)importFiles:(NSArray *)files withDialog:(BOOL)dialog
{
    // First expand directories and only keep paths to files
    NSArray *paths = [files expandPaths];
        
    NSString *path;
    NSMutableArray *filesInfo = [NSMutableArray array];
    NSString *prefix = [NSString commonPathComponentInPaths:paths]; 
    
    for (path in paths) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:path forKey:FILEDATA_PATH];
        [info setObject:[path fileSizeForPath] forKey:FILEDATA_SIZE];
        [info safeSetObject:[path mimeTypeForPath] forKey:FILEDATA_TYPE withValueForNil:@"application/octet-stream"];
        [info setObject:[path substringFromIndex:[prefix length]] forKey:FILEDATA_KEY];
        [filesInfo addObject:info];
    }
    
    [self setUploadData:filesInfo];

    NSString* defaultPrivacy = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_PRIVACY];
    if (defaultPrivacy==nil) {
        defaultPrivacy = ACL_PRIVATE;        
    }
    [self setUploadACL:defaultPrivacy];
    [self setUploadSize:[NSString readableSizeForPaths:paths]];

    if (!dialog)
        [self uploadFiles];
    else
    {
        if ([paths count]==1)
        {
            [self setUploadFilename:[[paths objectAtIndex:0] stringByAbbreviatingWithTildeInPath]];
            [NSApp beginSheet:uploadSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];			
        }
        else
        {
            [self setUploadFilename:[NSString stringWithFormat:NSLocalizedString(@"%d elements in %@",nil),[paths count],[prefix stringByAbbreviatingWithTildeInPath]]];
            [NSApp beginSheet:multipleUploadSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];							
        }
    }
}


- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    NSArray *files = [panel filenames];
    
    if (returnCode != NSOKButton) {
        [panel release];
        return;
    }
    [panel release];

    [self importFiles:files withDialog:TRUE];
}

- (void)didEndRenameSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    S3Object *source = (S3Object *)contextInfo;
    [source autorelease];

    [sheet orderOut:self];

    if (returnCode!=SHEET_OK) {
        return;
    }
    
    if ([[source key] isEqualToString:[self renameName]]) {
        return;
    }
    
    S3Object *newObject = [[S3Object alloc] initWithBucket:[self bucket] key:[self renameName]];
        
    S3CopyObjectOperation *copyOp = [[S3CopyObjectOperation alloc] initWithConnectionInfo:[self connectionInfo] from:source to:newObject];
    [newObject release];
    
    [_renameOperations addObject:copyOp];
    
    [self addToCurrentOperations:copyOp];
}

- (IBAction)rename:(id)sender
{
    NSArray *objects = [_objectsController selectedObjects];
    if ([objects count] == 0 || [objects count] > 1) {
        return;
    }
    S3Object *selectedObject = [[_objectsController selectedObjects] objectAtIndex:0];
    [self setRenameName:[selectedObject key]];
    [NSApp beginSheet:renameSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndRenameSheet:returnCode:contextInfo:) contextInfo:[selectedObject retain]];
}

#pragma mark -
#pragma mark Key-value coding

- (void)addObjects:(NSArray *)a
{
    [self willChangeValueForKey:@"objects"];
    [_objects addObjectsFromArray:a];
    [self didChangeValueForKey:@"objects"];
}

- (NSMutableArray *)objects
{
    return _objects; 
}

- (void)setObjects:(NSMutableArray *)aObjects
{
    [_objects release];
    _objects = [aObjects retain];
}

- (NSMutableDictionary *)objectsInfo
{
    return _objectsInfo; 
}

- (void)setObjectsInfo:(NSMutableDictionary *)aObjectsInfo
{
    [_objectsInfo release];
    _objectsInfo = [aObjectsInfo retain];
}

- (S3Bucket *)bucket
{
    return _bucket; 
}

- (void)setBucket:(S3Bucket *)aBucket
{
    [_bucket release];
    _bucket = [aBucket retain];
}

- (NSString *)renameName
{
    return _renameName;
}

- (void)setRenameName:(NSString *)name
{
    [_renameName release];
    _renameName = [name retain];
}

- (NSString *)uploadACL
{
    return _uploadACL; 
}

- (void)setUploadACL:(NSString *)anUploadACL
{
    [_uploadACL release];
    _uploadACL = [anUploadACL retain];
    [[NSUserDefaults standardUserDefaults] setObject:anUploadACL forKey:DEFAULT_PRIVACY];
}

- (NSString *)uploadFilename
{
    return _uploadFilename; 
}

- (void)setUploadFilename:(NSString *)anUploadFilename
{
    [_uploadFilename release];
    _uploadFilename = [anUploadFilename retain];
}

- (NSString *)uploadSize
{
    return _uploadSize; 
}

- (void)setUploadSize:(NSString *)anUploadSize
{
    [_uploadSize release];
    _uploadSize = [anUploadSize retain];
}

- (NSMutableArray *)uploadData
{
    return [[_uploadData retain] autorelease]; 
}

- (void)setUploadData:(NSMutableArray *)data
{
    [_uploadData release];
    _uploadData = [data retain];
}

- (BOOL)validList
{
    return _validList;
}

- (void)setValidList:(BOOL)yn
{
    _validList = yn;
}

- (NSString *)validListString
{
    if ([self validList] == YES) {
        return NSLocalizedString(@"Object list valid",nil);
    } else {
        return NSLocalizedString(@"Object list invalid",nil);
    }
}

#pragma mark -
#pragma mark Dealloc

-(void)dealloc
{
    [[[NSApp delegate] queue] removeQueueListener:self];
    
    [_renameOperations release];
    [_redirectConnectionInfoMappings release];
    
    [self setObjects:nil];
    [self setObjectsInfo:nil];
    [self setBucket:nil];

    [self setUploadACL:nil];
    [self setUploadFilename:nil];
    [self setUploadData:nil];
    
    [super dealloc];
}

@end
