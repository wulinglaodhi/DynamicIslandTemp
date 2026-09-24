ARCHS = arm64
TARGET = iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DynamicIslandTemp

DynamicIslandTemp_FILES = Tweak.x
DynamicIslandTemp_CFLAGS = -fobjc-arc
DynamicIslandTemp_FRAMEWORKS = UIKit Foundation
DynamicIslandTemp_PRIVATE_FRAMEWORKS = IOKit

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += DynamicIslandTempPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk