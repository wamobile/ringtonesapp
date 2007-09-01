/* RTRingtoneController */

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "RTRingtoneStore.h"
#import "RTRingtone.h"
#import "MobileDevice.h"
#import "iMediaBrowser/iMedia.h"

#define RTAudioFilePboardType (@"RTAudioFilePboardType")

@interface RTRingtoneController : NSObject
{
	IBOutlet NSWindow *_mainWindow; 
	IBOutlet NSTableView *ringtones;
	IBOutlet NSTextField *status;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet RTRingtoneStore *storeController;
	IBOutlet NSButton *gearButton;
	IBOutlet NSButton *clipButton;
	IBOutlet NSPopUpButton *fakePopup;
	
	struct am_device_notification *notif; 
	
	BOOL isDisconnected;
}


-(void)addFile;
-(void)removeRingtone;
-(void)read;
-(void)update;
-(void)openBrowser;
-(void)quickEditObjects:(NSArray *)someObjects;
-(void)backupRingtones:(id)threadParameters;


-(IBAction)gearMenu:(id)sender;
-(IBAction)quickClip:(id)sender;
-(IBAction)quickClipAll:(id)sender;
-(IBAction)openFile:(id)sender;
-(IBAction)browse:(id)sender;
-(IBAction)updateAction:(id)sender;
-(IBAction)remove:(id)sender;
-(IBAction)backup:(id)sender;
-(IBAction)quickEdit:(id)sender;
-(IBAction)quickEditAll:(id)sender;


-(void)buildScript;
-(NSString *)escapeSpaces:(NSString *)aString;
-(void)quickClipObjects:(NSArray *)someRingtones;
-(void)updateImageForRingtone:(RTRingtone *)aRingtone;
-(void)updateImagesForRingtones:(NSArray *)someRingtones;
-(NSString *)createPlistForStoreController;
-(void)setStatus:(NSString *)aStatus spin:(BOOL)shouldSpin;
-(NSString *)resolveTildeAndSymlinks:(NSString *)aPath;

-(BOOL)isDisconnected;
-(void)setDisconnected:(BOOL)disconnected;

@end
