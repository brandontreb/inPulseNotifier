#import "INAlertManager.h"

#import <BTstack/BTstackManager.h>
#import <BTstack/BTDiscoveryViewController.h>
#import <btstack/hci_cmds.h>
#import <btstack/BTDevice.h>

#import "inPulseProtocol.h"

@interface INAlertManager (Private)
- (void) flushPendingAlerts;
- (void) sendConnectionMessage;
- (void) asyncStart;
- (void) asyncConnect;
@end

// address of watch
bd_addr_t addr = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00};	// inPulse

@implementation INAlertManager

@synthesize connected;

int store_inpulse_string(char *dest, const char *string){
	int len = strlen(string) + 1;
	*dest++ = len;
	strcpy(dest, string);
	return len+1;
}

- (id) init {
	self = [super init];
	if(self) {
		// BTstack
		BTstackManager * bt = [BTstackManager sharedInstance];
		[bt setDelegate:self];
		[bt addListener:self];
		
		BTstackError err = [bt activate];
		if (err) NSLog(@"activate err 0x%02x!", err);
		
		pendingAlerts = [[NSMutableArray alloc] init];
		
		preferenceManager = [[INPreferenceManager alloc] init];
	}
	
	return self;
}

// direct access
-(void) btstackManager:(BTstackManager*) manager
  handlePacketWithType:(uint8_t) packet_type
			forChannel:(uint16_t) channel
			   andData:(uint8_t *)packet
			   withLen:(uint16_t) size
{
	bd_addr_t event_addr;
	
	switch (packet_type) {			
		case L2CAP_DATA_PACKET:			
			break;			
		case HCI_EVENT_PACKET:
			
			switch (packet[0]){
				case L2CAP_EVENT_CHANNEL_OPENED:
					// inform about new l2cap connection
					bt_flip_addr(event_addr, &packet[3]);
					//uint16_t psm = READ_BT_16(packet, 11); 
					source_cid = READ_BT_16(packet, 13); 
					con_handle = READ_BT_16(packet, 9);
					if (packet[2] == 0) {
						/*printf("Channel successfully opened: ");
						print_bd_addr(event_addr);
						printf(", handle 0x%02x, psm 0x%02x, source cid 0x%02x, dest cid 0x%02x\n",
							   con_handle, psm, source_cid,  READ_BT_16(packet, 15));*/
						connected = YES;
						[self sendConnectionMessage];
						[self flushPendingAlerts];
					} else {
						/*printf("L2CAP connection to device ");
						print_bd_addr(event_addr);
						printf(" failed. status code %u\n", packet[2]);*/
						connected = NO;
						/*NSString *address = [preferenceManager.preferences valueForKey:@"inpulseWatchAddress"];
						UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"inPulseNotifier" 
							message:[NSString stringWithFormat:@"Unable to connect to watch '%@'",address] 
							delegate:nil 
							cancelButtonTitle:@"OK" 
							otherButtonTitles:nil] autorelease];
					    [alert show];*/
					}
					break;
				default:
					break;
			}
			break;
			
		default:
			break;
	}	
}

- (void) flushPendingAlerts {
	for(int x = 0; x < [pendingAlerts count]; x++) {
		INAlertData *data = [pendingAlerts objectAtIndex:x];
		[self newAlertWithData:data];
	}
	[pendingAlerts removeAllObjects];
}

- (void) sendConnectionMessage {
	INAlertData *data = [[[INAlertData alloc] init] autorelease];
	data = [[[INAlertData alloc] init] autorelease];
    data.time = [NSDate date];
	data.status = kNewAlertForeground;
    data.type = kGenericAlert;
    data.bundleID = @"com.apple.iphone";
	data.header = @"iPhone";
	data.text = @"Connected to inPulse!";
	[self newAlertWithData:data];
	[self setTime];
}

-(void)newAlertWithData:(INAlertData *)data {
	if(!connected) {
		if(![pendingAlerts containsObject:data]) {
			[pendingAlerts addObject:data];
		}		
		return;
	}	
	
	uint8_t buffer[256];
	notification_message_header * message = (notification_message_header*) &buffer;
	message->message_header.endpoint = PP_ENDPOINT_NOTIFICATION;
	message->message_header.header_length = 8;
	message->message_header.time = time(NULL);
	message->notification_type = data.type;
	message->pp_alert_configuration_t.on1 = 10;
	message->pp_alert_configuration_t.type = 1;
	int pos = sizeof(notification_message_header);
	int len;

	const char *sndr = [[data header] UTF8String];
	const char *msg = [[data text] UTF8String];
	len = store_inpulse_string((char*)&buffer[pos], sndr); pos += len;
	len = store_inpulse_string((char*)&buffer[pos], msg);
	pos += len;
	message->message_header.length = pos;

    bt_send_l2cap( source_cid, (uint8_t*) &buffer, pos);
}

- (void) setTime {
	struct timecmd {
		command_query_header cmd;
		struct tm ts;
	} __attribute__((packed)) timecmd;
	
	time_t now;
	struct tm *ts;
	
	now = time(NULL);
	ts = localtime(&now);
	memcpy(&timecmd.ts, ts, sizeof(struct tm));
	
	timecmd.cmd.message_header.endpoint = PP_ENDPOINT_COMMAND;
	timecmd.cmd.message_header.header_length = sizeof(timecmd.cmd.message_header);
	timecmd.cmd.message_header.length = sizeof(timecmd);
	timecmd.cmd.command = command_set_time;
	timecmd.cmd.parameter1 = now;
	timecmd.cmd.parameter2 = +1;
	
    bt_send_l2cap( source_cid, (uint8_t*) &timecmd, 50);
}

// Listener methods
-(void) sleepModeEnterBTstackManager:(BTstackManager*) manager {
}

-(void) sleepModeExtitBTstackManager:(BTstackManager*) manager {	

}

// btstack
-(void) activatedBTstackManager:(BTstackManager*) manager {
	connected = NO;
	//[self performSelectorInBackground:@selector(asyncStart) withObject:nil];
	[self asyncStart];
}

-(void) deactivatedBTstackManager:(BTstackManager*) manager {
	connected = NO;
}

- (void)connectToWatch {
	//[BTDevice address:&addr fromString:@"00:50:C2:79:EE:20"];	
	[self performSelectorInBackground:@selector(asyncConnect) withObject:nil];
}

- (void) reloadPreferences {
	[preferenceManager reloadPreferences];
	[self connectToWatch];
}

- (void) asyncConnect {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *address = [preferenceManager.preferences valueForKey:@"inpulseWatchAddress"];
	[BTDevice address:&addr fromString:address];	
	BTstackManager * bt = [BTstackManager sharedInstance];
	[bt activate];
	[pool release];
}

- (void) asyncStart {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	bt_send_cmd(&l2cap_create_channel, addr, 0x1001);
	[pool release];
}

// Power Management
- (void)powerMessageReceived:(natural_t)messageType withArgument:(void *) messageArgument {
	
}

- (void) dealloc {
	[pendingAlerts release];
	[preferenceManager release];
	[super dealloc];
}

@end