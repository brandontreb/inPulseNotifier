/**
 * This is a modified version of Peter Hajas' MNAlertData class
 * It's pretty much identical except it has the defines needed for the
 * inPulse protocol
 */
#define kNewAlertForeground 0
#define kNewAlertBackground 1
#define kOldAlert 2

#define kPushAlert 0
#define kSMSAlert 1
#define kCalendarAlert 5
#define kPhoneAlert 3
#define kGenericAlert 8

@interface INAlertData :NSObject {
	NSString *header;
	NSString *text;
	int type;
	NSString *bundleID;
	NSDate *time;
	int status;
}

-(id)initWithHeader:(NSString*)_header withText:(NSString*)_title andType:(int)_type forBundleID:(NSString*)_bundleID atTime:(NSDate*)_time ofStatus:(int)_status;
-(id)initWithHeader:(NSString*)_header withText:(NSString*)_title andType:(int)_type forBundleID:(NSString*)_bundleID ofStatus:(int)_status;

@property(nonatomic, retain) NSString *header;
@property(nonatomic, retain) NSString *text;
@property(nonatomic) int type;
@property(nonatomic, retain) NSString *bundleID;
@property(nonatomic, retain) NSDate *time;
@property(nonatomic) int status;

@end