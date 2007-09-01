#import "RTRingtoneController.h"

@implementation RTRingtoneController

void *selfPtr;

void notification_callback(struct am_device_notification_callback_info *info)
{
	struct am_device *dev = info->dev;
	unsigned int msg = info->msg;
	
	if((AMDeviceIsPaired(dev) && msg != ADNCI_MSG_DISCONNECTED) || msg == ADNCI_MSG_CONNECTED) {
		[(id)selfPtr setDisconnected:NO];
		[(id)selfPtr read];
		[(id)selfPtr setStatus:@"Connected" spin:NO];
	}
	
	if(msg == ADNCI_MSG_DISCONNECTED) {
		[(id)selfPtr setDisconnected:YES];
		//This is kind of strange, but since the phone is disconnected, this call actually removes everything from the storeController.
		[(id)selfPtr read];
		[(id)selfPtr setStatus:@"Disconnected" spin:NO];
	}
}


- (id) init {
	self = [super init];
	if (self != nil) {
		[NSApp setDelegate:self];
		[status setHidden:YES];
		selfPtr = (void *)self;
		//store = [[RTRingtoneStore alloc] init];
		AMDeviceNotificationSubscribe(notification_callback, 0, 0, 0, &notif);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusNotification:) name:@"RTStatusChangedNotification" object:nil];
		[ringtones registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
		

	}
	return self;
}

-(void)awakeFromNib
{
	//Setup the NSOutlineView data source.
	[ringtones setDataSource:storeController];
	[ringtones setDelegate:storeController];
	[[ringtones tableColumnWithIdentifier:@"RTDevice"] setDataCell:[[NSImageCell alloc] init]];
	[ringtones reloadData];
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"RTToolbar"];
	[toolbar setDelegate:self];
	[_mainWindow setToolbar:toolbar];
	[gearButton setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"Gear.png"]]];
	[clipButton setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"clip.png"]]];
}
	

-(void)applicationWillTerminate:(NSNotification *)note
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeFileAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"Ringtones.plist"] handler:nil];
	[fileManager release];
}

#pragma mark Toolbar Delegate methods
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [NSArray arrayWithObjects: @"RTToolbarBrowse", @"RTToolbarRemoveRingtone", NSToolbarFlexibleSpaceItemIdentifier, @"RTToolbarUpdate", nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects: @"RTToolbarBrowse", @"RTToolbarRemoveRingtone", NSToolbarFlexibleSpaceItemIdentifier, @"RTToolbarUpdate", nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	return YES;
}


- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
      itemForItemIdentifier:(NSString *)itemIdentifier
  willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
 
    if ([itemIdentifier isEqual: @"RTToolbarBrowse"]) {
		// Set the text label to be displayed in the 
		// toolbar and customization palette 
		[toolbarItem setLabel:@"Browse"];
		[toolbarItem setPaletteLabel:@"Browse"];
 
		// Set up a reasonable tooltip, and image
		// you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:@"Browse your computer for music"];
		[toolbarItem setImage:[NSImage imageNamed:@"browse.png"]];
 
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(openBrowser)];
    } 
	
	else if([itemIdentifier isEqual: @"RTToolbarRemoveRingtone"])  {
		[toolbarItem setLabel:@"Remove"];
		[toolbarItem setPaletteLabel:@"Remove"];
	
		[toolbarItem setToolTip:@"Remove a Ringtone"];
		[toolbarItem setImage:[NSImage imageNamed:@"remove.png"]];

		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(removeRingtone)];
	}
	
	else if([itemIdentifier isEqual: @"RTToolbarUpdate"])  {
		[toolbarItem setLabel:@"Update iPhone"];
		[toolbarItem setPaletteLabel:@"Update iPhone"];
	
		[toolbarItem setImage:[NSImage imageNamed:@"update.png"]];
		[toolbarItem setToolTip:@"Update your iPhone"];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(update)];
	}
	
	else  {
    // itemIdentifier referred to a toolbar item that is not
    // provided or supported by us or Cocoa 
    // Returning nil will inform the toolbar
    // that this kind of item is not supported 
    toolbarItem = nil;
    }
    return toolbarItem;
}

-(void)openBrowser
{
	iMediaBrowser *browser = [iMediaBrowser sharedBrowser];
	[browser showWindow:self];
}

-(void)addFile
{
	[self setStatus:@"Adding..." spin:YES];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setCanChooseDirectories:YES];
	
	int ret = [openPanel runModalForDirectory:NSHomeDirectory() file:nil types:[NSArray arrayWithObjects:@"mp3", @"m4a", nil]];
	
	if(ret != NSOKButton)
		return;
	
	NSMutableArray *addedFiles = [[NSMutableArray alloc] init];
	id object;
	NSEnumerator *openedEnum = [[openPanel filenames] objectEnumerator];
	while(object = [openedEnum nextObject]) {
		[addedFiles addObjectsFromArray:[storeController parseContentsAtPath:object]];
	}
	[storeController insertObjects:addedFiles atArrangedObjectIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, [addedFiles count])]];
	[self setStatus:@"Done!" spin:NO];
}

-(void)removeRingtone
{
	if([self isDisconnected]) {
		[storeController removeObjectAtArrangedObjectIndex:[storeController selectionIndex]];
		return;
	}
	if([[storeController arrangedObjects] count] > 0) {
		id object;
		NSEnumerator *selectedEnum = [[[storeController arrangedObjects] objectsAtIndexes:[storeController selectionIndexes]] objectEnumerator];
		while(object = [selectedEnum nextObject]) {
			[self setStatus:@"Removing..." spin:YES];
			if([object isOnPhone]) {
				NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
				NSTask *removeTask = [[NSTask alloc] init];
				[removeTask setLaunchPath:[bundlePath stringByAppendingPathComponent:@"Contents/Resources/iphuc-universal-nr"]];
				[removeTask setArguments:[NSArray arrayWithObjects: @"-qvdo", [NSString stringWithFormat:@"rmdir \\%@", [NSString stringWithFormat:@"/iTunes_Control/Ringtones/%@", [self escapeSpaces:[[object path] lastPathComponent]]]], nil]];
				[removeTask launch];
				[removeTask waitUntilExit];
				[storeController removeObjectAtArrangedObjectIndex:[storeController selectionIndex]];
				
				NSTask *updatePlistTask = [[NSTask alloc] init];
				[updatePlistTask setLaunchPath:[bundlePath stringByAppendingPathComponent:@"Contents/Resources/iphuc-universal-nr"]];
				[updatePlistTask setArguments:[NSArray arrayWithObjects: @"-qvdo", [NSString stringWithFormat:@"putfile \\%@ \\/iTunes_Control/iTunes/Ringtones.plist", [self createPlistForStoreController]], nil]];
				[updatePlistTask launch];
				[updatePlistTask waitUntilExit]; 
			}
			else
				[storeController removeObjectAtArrangedObjectIndex:[storeController selectionIndex]];
		}
	}
	[self setStatus:@"Done!" spin:NO];
}

-(void)read
{
	[self setStatus:@"Reading..." spin:YES];
	NSEnumerator *storeEnumerator = [[storeController arrangedObjects] objectEnumerator];
	//If we have any items in the array controller, and we try to read, let's get rid of them, they are most likely invalid.
	if([[storeController arrangedObjects] count] > 0) {
		id object;
		while(object = [storeEnumerator nextObject]) {
			if([object isOnPhone]) {
				[storeController removeObject:object];
			}
		}
	}
	
	if([self isDisconnected]) {
		return;
	}
	
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSTask *readTask = [[NSTask alloc] init];
	[readTask setLaunchPath:[bundlePath stringByAppendingPathComponent:@"Contents/Resources/iphuc-universal-nr"]];
	[readTask setArguments:[NSArray arrayWithObjects: @"-qo", [NSString stringWithFormat:@"getfile \\/iTunes_Control/iTunes/Ringtones.plist %@", [NSTemporaryDirectory() stringByAppendingPathComponent:@"Ringtones.plist"]], nil]];
	[readTask launch];
	[readTask waitUntilExit];
	
	if([readTask terminationStatus] == 255) {
		NSDictionary *ringtonePlist = [NSDictionary dictionaryWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"/Ringtones.plist"]];
		NSArray *readRingtones = [RTRingtone fromPlist:ringtonePlist];
		[storeController calculateLengthsForRingtones:readRingtones];
		[self updateImagesForRingtones:readRingtones];
		[storeController addObjects:readRingtones];
	}
	[self setStatus:@"Done!" spin:NO];
}
	
	
		


-(void)update
{
	if([self isDisconnected]) {
		return;
	}

	[self setStatus:@"Updating..." spin:YES];
	[progressIndicator startAnimation:self];
	[progressIndicator setHidden:NO];
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	[self buildScript];	
	[[NSTask launchedTaskWithLaunchPath:[bundlePath stringByAppendingPathComponent:@"Contents/Resources/iphuc-universal-nr"]  arguments:[NSArray arrayWithObjects: @"-qs", [bundlePath stringByAppendingPathComponent:@"Contents/Resources/iphone.sh"], nil]] waitUntilExit];
	id object;
	NSEnumerator *ringtoneEnum = [[storeController arrangedObjects] objectEnumerator];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	while(object = [ringtoneEnum nextObject]) {
		if([object isClip]) {
			[fileManager removeFileAtPath:[object path] handler:nil];
		}
	}
	[fileManager release];
	[self setStatus:@"Done!" spin:NO];
	
	id removeObject;
	NSEnumerator *storeEnumerator = [[storeController arrangedObjects] objectEnumerator];
	while(removeObject = [storeEnumerator nextObject]) {
		[storeController removeObject:removeObject];
	}
	
	[self read];
	
}

-(NSString *)createPlistForStoreController
{
	id object = nil;
	NSMutableDictionary  *plist = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *subPlist = [[NSMutableDictionary alloc] init];
	NSEnumerator *storeEnumerator = [[storeController arrangedObjects] objectEnumerator];
	while(object = [storeEnumerator nextObject]) {
		[subPlist setObject:[object toPlist] forKey:[[object path] lastPathComponent]];
	}
	[plist setObject:subPlist forKey:@"Ringtones"];
	
	NSString *saveTo = ([NSTemporaryDirectory() stringByAppendingPathComponent:@"Ringtones.plist"]);
	[plist writeToFile:saveTo atomically:YES];
	
	return saveTo;
}

-(void)buildScript
{
	//This method builds the script that gets passed to iPHUC. Since iPHUC can't have arguments to it's script, we have to generate the script at runtime for it to work.
	NSMutableString *script = [[NSMutableString alloc] init];
	id object;
	[script appendString:@"mkdir /iTunes_Control/Ringtones\ncd /iTunes_Control/Ringtones\n"];
	NSEnumerator *storeEnumerator = [[storeController arrangedObjects] objectEnumerator];
	while(object = [storeEnumerator nextObject]) {
		
		if(![object isOnPhone] || [object isChanged])
			[script appendString:[NSString stringWithFormat:@"putfile %s\n", [[self escapeSpaces:[object path]] cStringUsingEncoding:NSUTF8StringEncoding]]];
	}
	[script appendString:@"cd /iTunes_Control/iTunes\n"];
	[script appendString:[NSString stringWithFormat:@"putfile %s\nexit", [[self createPlistForStoreController] cStringUsingEncoding:NSUTF8StringEncoding]]];
	
	NSError *error;
	[script writeToFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/iphone.sh"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

-(NSString *)escapeSpaces:(NSString *)aString
{
	return [[aString componentsSeparatedByString:@" "] componentsJoinedByString:@"\\ "];
}
	
	

-(IBAction)gearMenu:(id)sender
{
	[[fakePopup cell] performClickWithFrame:[sender frame] inView:[sender superview]];
}

-(IBAction)quickClip:(id)sender
{
	[self quickClipObjects:[storeController selectedObjects]];
}

-(IBAction)quickClipAll:(id)sender
{
	[self quickClipObjects:[storeController arrangedObjects]];
}


-(void)quickClipObjects:(NSArray *)someRingtones
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//First things first, we need our Ringtones directory. We use ~/Music to be a nice citizen.
	[self setStatus:@"Clipping..." spin:YES];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//Existance check.
	BOOL dirExists = NO;
	if(![fileManager fileExistsAtPath:[self resolveTildeAndSymlinks:@"~/Music/Ringtones"] isDirectory:&dirExists] && !dirExists) {
		NSLog(@"Creating directory");
		NSLog(@"%@", [self resolveTildeAndSymlinks:@"~/Music/Ringtones"]);
		[fileManager createDirectoryAtPath:[self resolveTildeAndSymlinks:@"~/Music/Ringtones"] attributes:nil];
	}
			
	id object;
	NSEnumerator *objectEnum = [someRingtones objectEnumerator];
	
	while(object = [objectEnum nextObject]) {
		if([object isOnPhone]) {
			//If the object is on the phone, we need to pull it off the phone before we attempt to Quick Clip it.
			NSTask *readTask = [[NSTask alloc] init];
			[readTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/iphuc-universal-nr"]];
			[readTask setArguments:[NSArray arrayWithObjects: @"-qo", [NSString stringWithFormat:@"getfile \\%@ %@", [self escapeSpaces:[object path]], [self escapeSpaces:[[self resolveTildeAndSymlinks:@"~/Music/Ringtones"] stringByAppendingPathComponent:[[object path] lastPathComponent]]]], nil]];
			[readTask launch];
			[readTask waitUntilExit];
			
			NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
			NSTask *removeTask = [[NSTask alloc] init];
			[removeTask setLaunchPath:[bundlePath stringByAppendingPathComponent:@"Contents/Resources/iphuc-universal-nr"]];
			[removeTask setArguments:[NSArray arrayWithObjects: @"-qo", [NSString stringWithFormat:@"rmdir \\%@", [NSString stringWithFormat:@"/iTunes_Control/Ringtones/%@", [self escapeSpaces:[[object path] lastPathComponent]]]], nil]];
			[removeTask launch];
			[removeTask waitUntilExit];
			
			[storeController removeObject:object];
			
			object = [[RTRingtone alloc] initWithPath:[[self resolveTildeAndSymlinks:@"~/Music/Ringtones"] stringByAppendingPathComponent:[[object path] lastPathComponent]]];
		}
		
		NSError *anError;
		QTMovie *ringtone = [[QTMovie alloc] initWithFile:[object path] error:&anError];
		NSNumber *scale = [ringtone attributeForKey:QTMovieTimeScaleAttribute];
		QTTime beginning = QTMakeTime(0, [scale longValue]);
		QTTime firstCut = QTMakeTime(30 * [scale longValue], [scale longValue]);
		QTTimeRange clipRange = QTMakeTimeRange(beginning, firstCut);
		
		QTMovie *clippedRingtone = [[QTMovie alloc] initWithMovie:ringtone timeRange:clipRange error:&anError];
						
		NSDictionary *savedMovieAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], QTMovieExport, [NSNumber numberWithLong:kQTFileTypeMP4], QTMovieExportType, nil];
		[clippedRingtone writeToFile:[[self resolveTildeAndSymlinks:@"~/Music/Ringtones"] stringByAppendingPathComponent:[[object name] stringByAppendingString:@".m4a"]] withAttributes:savedMovieAttributes];
		[ringtone release];
		[clippedRingtone release];
		
		[storeController removeObject:object];
		
		RTRingtone *clip = [[RTRingtone alloc] initWithPath:[[self resolveTildeAndSymlinks:@"~/Music/Ringtones"] stringByAppendingPathComponent:[[object name] stringByAppendingString:@".m4a"]]];		
		[storeController calculateLengthForRingtone:clip];
		[self updateImageForRingtone:clip];
		[storeController addObject:clip];
	}
	[fileManager release];
	[self setStatus:@"Done!" spin:NO];
	[pool release];
}

-(IBAction)quickEdit:(id)sender
{
	[self quickEditObjects:[storeController selectedObjects]];
}

-(IBAction)quickEditAll:(id)sender
{
	[self quickEditObjects:[storeController arrangedObjects]];
}

-(void)quickEditObjects:(NSArray *)someRingtones
{
	//Quick Edit removes the first three characters from the name of all selected objects.
	//These are usually the 2-digit track number and a space.
	[self setStatus:@"Editing..." spin:YES];
	RTRingtone *object;
	NSEnumerator *ringtoneEnum = [someRingtones objectEnumerator];
	
	while(object = [ringtoneEnum nextObject]) {
		[object setName:[[object name] substringWithRange:NSMakeRange(3, [[object name] length] - 3)]];
	}
	[self setStatus:@"Done!" spin:NO];
}
	

-(IBAction)openFile:(id)sender
{
	[self addFile];
}

-(IBAction)browse:(id)sender
{
	[self openBrowser];
}

-(IBAction)updateAction:(id)sender
{
	[self update];
}

-(IBAction)remove:(id)sender
{
	[self removeRingtone];
}

-(IBAction)backup:(id)sender
{
	[NSThread detachNewThreadSelector:@selector(backupRingtones:) toTarget:self withObject:[storeController arrangedObjects]];
}

-(void)backupRingtones:(id)threadParameters
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//First things first, we need our Ringtones directory. We use ~/Music to be a nice citizen.
	[self setStatus:@"Backing Up..." spin:YES];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	//Existance check.
	BOOL ringtonesExists = NO;
	BOOL backupExists = NO;
	if(![fileManager fileExistsAtPath:[self resolveTildeAndSymlinks:@"~/Music/Ringtones"] isDirectory:&ringtonesExists] && !ringtonesExists) {
		[fileManager createDirectoryAtPath:[self resolveTildeAndSymlinks:@"~/Music/Ringtones"] attributes:nil];
	}
	
	if(![fileManager fileExistsAtPath:[self resolveTildeAndSymlinks:@"~/Music/Ringtones/Backups"] isDirectory:&backupExists] && !backupExists) {
		[fileManager createDirectoryAtPath:[self resolveTildeAndSymlinks:@"~/Music/Ringtones/Backups"] attributes:nil];
	}
	
	NSString *backupDirectory = [[self resolveTildeAndSymlinks:@"~/Music/Ringtones/Backups"] stringByAppendingPathComponent:[NSString stringWithFormat:@"Backup-%@", [NSDate date]]];
	[fileManager createDirectoryAtPath:backupDirectory attributes:nil];
		
	id object;
	NSEnumerator *objectEnum = [threadParameters objectEnumerator];
	
	while(object = [objectEnum nextObject]) {
		if([object isOnPhone]) {
			//If the object is on the phone, we need to pull it off the phone before we attempt to Quick Clip it.
			NSTask *readTask = [[NSTask alloc] init];
			[readTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/iphuc-universal-nr"]];
			[readTask setArguments:[NSArray arrayWithObjects: @"-qo", [NSString stringWithFormat:@"getfile \\%@ %@", [self escapeSpaces:[object path]], [self escapeSpaces:[backupDirectory stringByAppendingPathComponent:[[object path] lastPathComponent]]], nil]]];
			[readTask launch];
			[readTask waitUntilExit];
		}	
	}
	[self setStatus:@"Done!" spin:NO];
	[pool release];
}

-(void)updateImageForRingtone:(RTRingtone *)aRingtone
{
	BOOL isOnPhone = [aRingtone isOnPhone];
	
	if(isOnPhone)
		[aRingtone setDeviceIcon:[storeController phoneImage]];
	else
		[aRingtone setDeviceIcon:[storeController computerImage]];
}

-(void)updateImagesForRingtones:(NSArray *)someRingtones {
	id object;
	NSEnumerator *ringtoneEnum = [someRingtones objectEnumerator];
	
	while(object = [ringtoneEnum nextObject]) {
		[self updateImageForRingtone:object];
	}
}

-(BOOL)isDisconnected
{
	return isDisconnected;
}
-(void)setDisconnected:(BOOL)disconnected
{
	isDisconnected = disconnected;
}

-(void)setStatus:(NSString *)aStatus spin:(BOOL)shouldSpin
{
	[status setStringValue:aStatus];
	if(!shouldSpin) {
		[progressIndicator setHidden:YES];
		[progressIndicator stopAnimation:self];
	}
	else {
		[progressIndicator setHidden:NO];
		[progressIndicator startAnimation:self];
	}
}

-(void)statusNotification:(NSNotification *)note
{
	NSDictionary *userInfo = [note userInfo];
	[self setStatus:[userInfo objectForKey:@"RTStatusChange"] spin:[[userInfo objectForKey:@"RTSpin"] boolValue]];
}

-(NSString *)resolveTildeAndSymlinks:(NSString *)aPath
{
	return [aPath stringByResolvingSymlinksInPath];
}

@end

