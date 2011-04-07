@interface INPreferenceManager : NSObject
{
	NSDictionary* preferences;
}

-(void)reloadPreferences;

@property (readonly) NSDictionary* preferences;

@end