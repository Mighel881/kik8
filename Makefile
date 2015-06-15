ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = Kik8
Kik8_FILES = Tweak.xm
Kik8_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += Kik8
include $(THEOS_MAKE_PATH)/aggregate.mk
