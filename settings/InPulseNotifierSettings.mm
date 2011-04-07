#import <Preferences/Preferences.h>

@interface InPulseNotifierSettingsListController: PSListController {
}
@end

@implementation InPulseNotifierSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"InPulseNotifierSettings" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
