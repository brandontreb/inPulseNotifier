#import "INPreferenceManager.h"
#import <btstack/hci_cmds.h>
#import <btstack/BTDevice.h>

@implementation INPreferenceManager

@synthesize preferences;

-(id)init
{
	self = [super init];
	if(self)
	{
		preferences = [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.brandontreb.inpulsenotifiersettings.plist"] retain];
	}
	return self;
}

-(void)reloadPreferences
{
	if(preferences)
	{
		[preferences release];
	}
	preferences = [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.brandontreb.inpulsenotifiersettings.plist"] retain];
}

- (void) dealloc {
	[preferences release];
	[super dealloc];
}

@end