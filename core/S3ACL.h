//
//  S3ACL.h
//  S3-Objc
//
//  Created by Olivier Gutknecht on 4/23/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _S3Permission
{
	S3READ_Permission
	
} S3Permission;


@interface S3Grantee : NSObject
@end

@interface S3CanonicalUserGrantee : NSObject {
	NSString* _id;
	NSString* _displayName;
}
@end

@interface S3EmailGrantee : NSObject {
	NSString* _email;
}
+(S3EmailGrantee*)emailGranteeWithAddress:(NSString*)email;
@end

@interface S3GroupGrantee : NSObject {
	NSString* _id;
}
+(S3GroupGrantee*)allUsersGroupGrantee;
+(S3GroupGrantee*)allAuthenticatedUsersGroupGrantee;
@end

@interface S3OwnerGrantee : NSObject {
	NSString* _id;
}
+(S3OwnerGrantee*)ownerGranteeWithID:(NSString*)uid;
@end


@interface S3Grant : NSObject {
	S3Grantee* _grantee;
	S3Permission _permission;
}

@end


@interface S3ACL : NSObject {
	NSString* _owner;
	NSMutableArray* _accessList;
}

@end

/*
 
 getACLTemplatePublicReadWrite
 
 <?xml version="1.0" encoding="UTF-8"?>
 <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
 <Owner>
 <ID>selfId</ID>
 </Owner>
 <AccessControlList>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
 <ID>selfId</ID>
 <DisplayName>duspense</DisplayName>
 </Grantee>
 <Permission>FULL_CONTROL</Permission>
 </Grant>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group">
 <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
 </Grantee>
 <Permission>READ</Permission>
 </Grant>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group">
 <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
 </Grantee>
 <Permission>WRITE</Permission>
 </Grant>
 </AccessControlList>
 </AccessControlPolicy>
 
 getACLTemplatePrivate
 
 <?xml version="1.0" encoding="UTF-8"?>
 <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
 <Owner>
 <ID>selfId</ID>
 </Owner>
 <AccessControlList>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
 <ID>selfId</ID>
 </Grantee>
 <Permission>FULL_CONTROL</Permission>
 </Grant>
 </AccessControlList>
 </AccessControlPolicy>
 
 
 getACLTemplatePublicRead
 
 <?xml version="1.0" encoding="UTF-8"?>
 <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
 <Owner>
 <ID>selfId</ID>
 </Owner>
 <AccessControlList>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
 <ID>selfId</ID>
 </Grantee>
 <Permission>FULL_CONTROL</Permission>
 </Grant>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group">
 <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
 </Grantee>
 <Permission>READ</Permission>
 </Grant>
 </AccessControlList>
 </AccessControlPolicy>

 */