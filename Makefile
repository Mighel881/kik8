ARCHS = armv7 arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Kik8
Kik8_FILES = Tweak.xm
Kik8_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Kik" # No Reason to kill SpringBoard since we're only injecting into kik
