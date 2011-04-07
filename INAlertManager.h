#import "INAlertData.h"
#import "BTStackManager.h"
#import "INPreferenceManager.h"

@interface INAlertManager: NSObject<BTstackManagerDelegate, BTstackManagerListener> {
	BOOL connected;
	NSMutableArray *pendingAlerts;
	INPreferenceManager *preferenceManager;
}

@property(nonatomic) BOOL connected;

- (void) newAlertWithData:(INAlertData *)data;
- (void) setTime;
- (void) connectToWatch;
- (void) reloadPreferences;
@end