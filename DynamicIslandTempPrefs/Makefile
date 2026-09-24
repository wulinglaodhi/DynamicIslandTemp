include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DynamicIslandTempPrefs

DynamicIslandTempPrefs_FILES = DynamicIslandTempPrefs.m
DynamicIslandTempPrefs_FRAMEWORKS = UIKit
DynamicIslandTempPrefs_PRIVATE_FRAMEWORKS = Preferences
DynamicIslandTempPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp $(PWD)/Resources/DynamicIslandTemp.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/DynamicIslandTemp.plist$(ECHO_END)