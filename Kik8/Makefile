ARCHS = armv7 arm64
include theos/makefiles/common.mk

BUNDLE_NAME = Kik8
Kik8_FILES = Kik8.mm
Kik8_INSTALL_PATH = /Library/PreferenceBundles
Kik8_FRAMEWORKS = UIKit
Kik8_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Kik8.plist$(ECHO_END)
