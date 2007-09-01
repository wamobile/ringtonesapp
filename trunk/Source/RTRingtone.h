//
//  RTRingtone.h
//  Ringtones
//
//  Created by Elliott Harris on 8/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <uuid/uuid.h>


@interface RTRingtone : NSObject <NSCoding> {
	//Plist attributes.
	NSString *name;
	NSString *guid;
	
	//Local attributes.
	NSString *path;
	NSTimeInterval length;
	NSImage *deviceIcon;
	BOOL isChanged;
}


-(id)initWithDictionary:(NSDictionary *)aDictionary;
+(NSArray *)fromPlist:(NSDictionary *)aPlist;
-(NSDictionary *)toPlist;
+(NSString *)generateUuid;


-(NSString *)path;
-(void)setPath:(NSString *)aPath;
-(NSString *)name;
-(void)setName:(NSString *)aName;
-(NSTimeInterval)length;
-(void)setLength:(NSTimeInterval)aLength;
-(NSString *)guid;
-(void)setGuid:(NSString *)aGuid;
-(NSImage *)deviceIcon;
-(void)setDeviceIcon:(NSImage *)aIcon;

-(BOOL)isClip;
-(BOOL)isOnPhone;
-(BOOL)isChanged;
-(void)setChanged:(BOOL)isChanged;

@end
