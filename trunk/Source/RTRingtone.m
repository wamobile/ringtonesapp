//
//  RTRingtone.m
//  Ringtones
//
//  Created by Elliott Harris on 8/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RTRingtone.h"

@implementation RTRingtone

-(void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:[self name] forKey:@"name"];
	[coder encodeObject:[self guid] forKey:@"guid"];

	[coder encodeDouble:(double)[self length]  forKey:@"length"];
	[coder encodeObject:[self path] forKey:@"path"];
	[self setChanged:YES];

}

-(id)initWithCoder:(NSCoder *)coder
{
	if(self = [super init]) {
		[self setName:[coder decodeObjectForKey:@"name"]];
		[self setGuid:[coder decodeObjectForKey:@"guid"]];
		[self setLength:[coder decodeDoubleForKey:@"length"]];
		[self setPath:[coder decodeObjectForKey:@"path"]];
		[self setChanged:YES];
	}
	
	return self;
}

-(id)initWithPath:(NSString *)aPath
{
	if(self = [super init]) {
		[self setPath:aPath];
		[self setName:[[aPath lastPathComponent] stringByDeletingPathExtension]];
		[self setGuid:[RTRingtone generateUuid]];
		[self setChanged:YES];
	}
	
	return self;
}

-(id)initWithDictionary:(NSDictionary *)aDictionary
{
	if(self = [super init]) {
		[self setName:[aDictionary objectForKey:@"Name"]];
		[self setGuid:[aDictionary objectForKey:@"GUID"]];
	}
	
	return self;
}

//Returns an array of RTRingtone objects create from aPlist.
+(NSArray *)fromPlist:(NSDictionary *)aPlist
{
	NSMutableDictionary *plist = [[aPlist objectForKey:@"Ringtones"] mutableCopy];
	NSMutableArray *retArray = [[NSMutableArray alloc] init];
	
	id key;
	NSEnumerator *plistEnum = [plist keyEnumerator];
	
	while(key = [plistEnum nextObject]) {
		RTRingtone *newRingtone = [[RTRingtone alloc] initWithDictionary:[plist objectForKey:key]];
		[newRingtone setPath:[@"/iTunes_Control/Ringtones" stringByAppendingPathComponent:key]];
		[retArray addObject:newRingtone];
	}
	
	return retArray;
}

-(NSDictionary *)toPlist
{
	NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
	[plist setObject:[self guid] forKey:@"GUID"];
	[plist setObject:[self name] forKey:@"Name"];
	return [plist copy];
}

-(NSString *)path
{
	return path;
}
-(void)setPath:(NSString *)aPath
{
	if ([path isEqual:aPath])
		return;
	[path release];
	path = [aPath retain];
}

-(NSString *)name
{
	return name;
}
-(void)setName:(NSString *)aName
{
	if ([name isEqual:aName])
		return;
	[name release];
	name = [aName retain];
}
	
-(NSTimeInterval)length
{
	return length;
}

-(void)setLength:(NSTimeInterval)aLength
{
	length = aLength;
}

-(NSString *)guid
{
	return guid;
}

-(void)setGuid:(NSString *)aGuid
{
	if([guid isEqual:aGuid])
		return;
	[guid release];
	guid = [aGuid retain];
}

-(BOOL)isChanged
{
	return isChanged;
}

-(void)setChanged:(BOOL)changed
{
	isChanged = changed;
}
-(NSImage *)deviceIcon
{
	return deviceIcon;
}

-(void)setDeviceIcon:(NSImage *)aIcon
{
	if(deviceIcon == aIcon)
		return;
	[deviceIcon release];
	deviceIcon = [aIcon retain];
}

-(BOOL)isClip
{
	return [[path stringByDeletingLastPathComponent] isEqual:[@"~/Music/Ringtones" stringByExpandingTildeInPath]];
}

-(BOOL)isOnPhone
{
	return [[path stringByDeletingLastPathComponent] isEqual:@"/iTunes_Control/Ringtones"];
}



+(NSString *)generateUuid
{
	uuid_t dateUuid, randomUuid;
	uuid_generate_time(dateUuid);
	uuid_generate_random(randomUuid);
	
	NSString *randomGuid = [[NSString alloc] initWithCString:(char *)randomUuid];
	NSString *dateGuid = [[NSString alloc] initWithCString:(char *)dateUuid];
	
	return [randomGuid stringByAppendingString:dateGuid];
	
}


@end
