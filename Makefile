include $(THEOS)/makefiles/common.mk

TWEAK_NAME = inPulseNotifier

inPulseNotifier_FILES = Tweak.xm BTstackManager.m BTDevice.m INPreferenceManager.m INAlertManager.m INAlertData.m
SUBPROJECTS = settings

include $(THEOS_MAKE_PATH)/tweak.mk
inPulseNotifier_FRAMEWORKS = IOKit UIKit Foundation QuartzCore CoreGraphics
inPulseNotifier_CFLAGS = -Iinclude 
inPulseNotifier_LDFLAGS = -lBTstack

SUBPROJECTS = settings
include $(FW_MAKEDIR)/aggregate.mk