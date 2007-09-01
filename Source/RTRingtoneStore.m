//
//  RTRingtoneStore.m
//  Ringtones
//
//  Created by Elliott Harris on 8/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RTRingtoneStore.h"


@implementation RTRingtoneStore

#pragma mark Table View dnd methods

- (void)awakeFromNib
{
	[tableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	
	phoneImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"device-phone.png"]];
	[phoneImage setName:@"phone"];
	computerImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"device-comp.png"]];
	[computerImage setName:@"comp"];
}


- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	id object;
	NSEnumerator *selectedEnum = [[[self arrangedObjects] objectsAtIndexes:rowIndexes] objectEnumerator];
	NSMutableArray *pasteboardArray = [[NSMutableArray alloc] init];
	
	while(object = [selectedEnum nextObject]) {
		if(![object isOnPhone])
			[pasteboardArray addObject:[object path]];
	}
	
	NSArray *pasteboardTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
	[pboard declareTypes:pasteboardTypes owner:self];
	
	[pboard setPropertyList:pasteboardArray forType:NSFilenamesPboardType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{	
	NSDragOperation dragOp = NSDragOperationCopy;
	
	NSDictionary *draggingDict = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	if(!draggingDict)	
		dragOp = NSDragOperationNone;
	
	[tv setDropRow:row dropOperation:dragOp];
	
	return dragOp;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	if(row < 0)
		row = 0;
	
	BOOL isTableViewSource = ([info draggingSource] == tableView);
	
	id object;
	NSMutableArray *droppedFiles = [[NSMutableArray alloc] init];
	
	NSArray *draggedFiles = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];		
	NSEnumerator *objEnum = [draggedFiles objectEnumerator];

	while(object = [objEnum nextObject]) {
		[droppedFiles addObjectsFromArray:[self parseContentsAtPath:object]];
	}
	//This fixes a bug where if the object is dragged past the index of the array, i.e. to the very end of the list, it would be deleted.
	if(isTableViewSource && row > [[self arrangedObjects] count]) {
		row = [[self arrangedObjects] count];
	}
	
	if(isTableViewSource) {
		id removeObject;
		NSEnumerator *droppedEnum = [droppedFiles objectEnumerator];
		
		while(removeObject = [droppedEnum nextObject]) {
			[self removeIdenticalPath:removeObject];
		}
	}

	[self insertObjects: droppedFiles atArrangedObjectIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange((unsigned int)row,[droppedFiles count])]];
	
	return YES;

}

-(NSMutableArray *)parseContentsAtPath:(NSString *)aPath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSMutableArray *contents = [[NSMutableArray alloc] init];
	
	BOOL isDirectory = NO;
	[fileManager fileExistsAtPath:aPath isDirectory:&isDirectory];
	
	id object;
	NSEnumerator *contentsEnum = [[fileManager directoryContentsAtPath:aPath] objectEnumerator];

	if(!isDirectory) {
		RTRingtone *newRingtone = [[RTRingtone alloc] initWithPath:aPath];
		[self calculateLengthForRingtone:newRingtone];
		[newRingtone setDeviceIcon:computerImage];
		[contents addObject:newRingtone];
	}
	
	while(object = [contentsEnum nextObject]) {
			
		if([[object pathExtension] isEqual:@""]) {
			[contents addObjectsFromArray:[self parseContentsAtPath:[aPath stringByAppendingPathComponent:object]]];
		}
		
		else if([[object pathExtension] isEqual:@"mp3"] || [[object pathExtension] isEqual:@"m4a"]) {
			RTRingtone *newRingtone = [[RTRingtone alloc] initWithPath:[aPath stringByAppendingPathComponent:object]];
			[self calculateLengthForRingtone:newRingtone];
			[newRingtone setDeviceIcon:computerImage];
			[contents addObject:newRingtone];
		}
	}
	
	NSLog(@"%@", contents);
	return contents;
}

-(void)removeIdenticalPath:(NSString *)path
{
	//This method removes objects in the controlled array that have this path.
	//Since we are dragging and dropping file paths, which are unique, we can remove a particular item by removing the object with it's path.
	id object;
	NSEnumerator *storeEnum = [[self arrangedObjects] objectEnumerator];
	
	while(object = [storeEnum nextObject]) {
		if([[object path] isEqual:path]) {
			[self removeObject:object];
			return;
		}
	}
}

//You might think this is a strange place for this method, but both the Store and the Controller need to do this
//depending on how the ringtone is added (drag/drop vs. add button), so both of them can use this! :)

-(void)calculateLengthForRingtone:(RTRingtone *)aRingtone
{
	id object = aRingtone;
	
	if([object isOnPhone]) {
		//Experimental! We grab the ringtone from the phone and use a local copy to determine the length.
		NSTask *readTask = [[NSTask alloc] init];
		[readTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/iphuc-universal-nr"]];
		[readTask setArguments:[NSArray arrayWithObjects: @"-qo", [NSString stringWithFormat:@"getfile \\%@ %@", [self escapeSpaces:[object path]], 
		[self escapeSpaces:[NSTemporaryDirectory() stringByAppendingPathComponent:[[object path] lastPathComponent]]]], nil]];
		[readTask launch];
		[readTask waitUntilExit];
		
		object = [[RTRingtone alloc] initWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[object path] lastPathComponent]]];
	}
	NSError *error;
	QTMovie *ringtone = [QTMovie movieWithFile:[object path] error:&error];
	QTTime qtLength = [ringtone duration];
	NSTimeInterval length;
	QTGetTimeInterval(qtLength, &length);
	[aRingtone setLength:length];
}

-(void)calculateLengthsForRingtones:(NSArray *)someRingtones
{
	RTRingtone *object;
	NSEnumerator *ringtoneEnum = [someRingtones objectEnumerator];
	
	while(object = [ringtoneEnum nextObject]) {
		[self calculateLengthForRingtone:object];
	}
}

-(NSString *)escapeSpaces:(NSString *)aString
{
	return [[aString componentsSeparatedByString:@" "] componentsJoinedByString:@"\\ "];
}

-(NSImage *)phoneImage
{
	return phoneImage;
}

-(NSImage *)computerImage
{
	return computerImage;
}

@end
