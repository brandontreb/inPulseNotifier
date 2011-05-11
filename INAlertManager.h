#import "INAlertData.h"
#import "BTStackManager.h"
#import "INPreferenceManager.h"
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>

@interface INAlertManager: NSObject<BTstackManagerDelegate, BTstackManagerListener> {
	BOOL connected;
	NSMutableArray *pendingAlerts;
	INPreferenceManager *preferenceManager;
	
	// Power Management
	io_connect_t root_port;
    io_object_t notifier;
}

@property(nonatomic) BOOL connected;

- (void) newAlertWithData:(INAlertData *)data;
- (void) setTime;
- (void) connectToWatch;
- (void) reloadPreferences;

// Power Management
- (void)powerMessageReceived:(natural_t)messageType withArgument:(void *) messageArgument;

@end