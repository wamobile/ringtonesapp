//
//  RTRingtoneStore.h
//  Ringtones
//
//  Created by Elliott Harris on 8/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "RTRingtone.h"


@interface RTRingtoneStore : NSArrayController {
	IBOutlet NSTableView *tableView;
	
	NSImage *phoneImage;
	NSImage *computerImage;
}

-(void)removeIdenticalPath:(NSString *)path;
-(void)calculateLengthForRingtone:(RTRingtone *)aRingtone;
-(void)calculateLengthsForRingtones:(NSArray *)someRingtones;
-(NSString *)escapeSpaces:(NSString *)aString;
-(NSMutableArray *)parseContentsAtPath:(NSString *)aPath;

-(NSImage *)phoneImage;
-(NSImage *)computerImage;




@end
