/**
 * Copyright (c) 2010-2011, Peter Hajas
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	    * Redistributions of source code must retain the above copyright
	      notice, this list of conditions and the following disclaimer.
	    * Redistributions in binary form must reproduce the above copyright
	      notice, this list of conditions and the following disclaimer in the
	      documentation and/or other materials provided with the distribution.
	    * Neither the name of the Peter Hajas nor the
	      names of its contributors may be used to endorse or promote products
	      derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * This is a modified version of Peter Hajas' Tweak.xm file
 * It uses all of the same code to grab notifications from the system and
 * has been modified to work with the inpulse watch code.
 */
#import <SpringBoard/SpringBoard.h>
#import <ChatKit/ChatKit.h>
#import <objc/runtime.h>

#import "INAlertData.h"
#import "INAlertManager.h"
#import "INPreferenceManager.h"

@interface INInterface : NSObject {

}
@end

//Mail class declaration for fetched messages
@interface AutoFetchRequestPrivate
-(BOOL)gotNewMessages;
-(int)messageCount;
@end

@implementation INInterface

-(id)init
{
	self = [super init];
	if(self)
	{
	
	}
	return self;
}

@end

//Alert Controller:
INAlertManager *manager;

//Hook into Springboard init method to initialize our window

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)application
{    
    %orig;

	INPreferenceManager *preferenceManager = [[[INPreferenceManager alloc] init] autorelease];
	BOOL enabled = [[preferenceManager.preferences valueForKey:@"inpulseEnabled"] boolValue];
	if(enabled) {
		manager = [[INAlertManager alloc] init];
		[manager connectToWatch];
	}
}

- (void) dealloc {
	[manager release];
	manager = nil;
	%orig;
}

%end;

%hook SBAlertItemsController

-(void)activateAlertItem:(id)item
{
	//Build the alert data part of the way
    INAlertData* data;    

	if([item isKindOfClass:%c(SBSMSAlertItem)])
	{
        //It's an SMS/MMS!
        data = [[[INAlertData alloc] init] autorelease];
        data.type = kSMSAlert;
        data.time = [NSDate date];
    	data.status = kNewAlertForeground;
		data.bundleID = [[NSString alloc] initWithString:@"com.apple.MobileSMS"];
		if([item alertImageData] == NULL)
		{
			data.header = [[NSString alloc] initWithFormat:@"%@", [item name]];
			data.text = [[NSString alloc] initWithFormat:@"%@", [item messageText]];
		}
	    else
	    {
			data.header = [[NSString alloc] initWithFormat:@"%@", [item name]];
			data.text = [[NSString alloc] initWithFormat:@"%@", [item messageText]];
	    }
		[manager newAlertWithData:data];
	}
    else if(([item isKindOfClass:%c(SBRemoteNotificationAlert)]) || 
			([item isKindOfClass:%c(SBRemoteLocalNotificationAlert)]))
    {
        //It's a push notification!
        
		//Get the SBApplication object, we need its bundle identifier
		SBApplication *app(MSHookIvar<SBApplication *>(item, "_app"));
		//Filter out clock alerts

		NSString* _body = MSHookIvar<NSString*>(item, "_body");
		data = [[[INAlertData alloc] init] autorelease];
		data.time = [NSDate date];
       	data.status = kNewAlertForeground;
		data.type = kPushAlert;
		data.bundleID = [app bundleIdentifier];
		data.header = [app displayName];
		data.text = _body;
		[manager newAlertWithData:data];

    }
    
    else if([item isKindOfClass:%c(SBVoiceMailAlertItem)])
    {
        //It's a voicemail alert!
        data = [[[INAlertData alloc] init] autorelease];
        data.time = [NSDate date];
    	data.status = kNewAlertForeground;
        data.type = kPhoneAlert;
        data.bundleID = @"com.apple.mobilephone";
        data.header = [item title];
        data.text = [item bodyText];
		[manager newAlertWithData:data];
    } else if([item isKindOfClass:%c(SBCalendarAlertItem)]) {
		// Calendar Appointment 
		NSString* _title = MSHookIvar<NSString*>(item, "_title");
		data = [[[INAlertData alloc] init] autorelease];
        data.type = kCalendarAlert;
        data.time = [NSDate date];
    	data.status = kNewAlertForeground;
		data.bundleID = [[NSString alloc] initWithString:@"com.apple.MobileSMS"];
		data.header = @"Calendar";
		data.text = _title;
		[manager newAlertWithData:data];
	 } else {
		// other alert
	}
	%orig;
}

-(void)deactivateAlertItem:(id)item {
	%orig;
}

%end

%hook AutoFetchRequestPrivate

-(void)run
{
	%orig;
    %log;
	if([self gotNewMessages])
	{
		//Build the alert data part of the way
		INAlertData* data = [[[INAlertData alloc] init] autorelease];
		//Current date + time
        data.time = [[NSDate date] retain];
		data.status = kNewAlertForeground;

	    data.type = kSMSAlert;
		data.bundleID = [[NSString alloc] initWithString:@"com.apple.MobileMail"];
		
		data.header = [[NSString alloc] initWithFormat:@"Mail"];
		data.text = [[NSString alloc] initWithFormat:@"%d new messages", [self messageCount]];
		
		[manager newAlertWithData:data];
	}
}

%end

static void reloadPrefsNotification(CFNotificationCenterRef center,
									void *observer,
									CFStringRef name,
									const void *object,
									CFDictionaryRef userInfo) {
	[manager reloadPreferences];
}

%ctor
{
	//Register for the preferences-did-change notification
	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterAddObserver(r, NULL, &reloadPrefsNotification, CFSTR("com.brandontreb.inpulsenotifier/reloadPrefs"), NULL, 0);
}

/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/
