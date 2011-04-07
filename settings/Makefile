include theos/makefiles/common.mk

BUNDLE_NAME = InPulseNotifierSettings
InPulseNotifierSettings_FILES = InPulseNotifierSettings.mm
InPulseNotifierSettings_INSTALL_PATH = /Library/PreferenceBundles
InPulseNotifierSettings_FRAMEWORKS = UIKit
InPulseNotifierSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/InPulseNotifierSettings.plist$(ECHO_END)
