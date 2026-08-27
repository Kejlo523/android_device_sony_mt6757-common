LOCAL_PATH := $(call my-dir)

ifneq ($(filter hinoki,$(TARGET_DEVICE)),)

# Compile-only descriptions of the Oreo MTK HIDL classes.  The real classes
# are provided at runtime by mediatek-telephony-common.jar from the stock ROM.
include $(CLEAR_VARS)
LOCAL_MODULE := hinoki-mtk-radio-stubs
LOCAL_SRC_FILES := $(call all-java-files-under, stubs)
LOCAL_JAVA_LIBRARIES := telephony-common
LOCAL_PRIVATE_PLATFORM_APIS := true
LOCAL_UNINSTALLABLE_MODULE := true
include $(BUILD_STATIC_JAVA_LIBRARY)

include $(CLEAR_VARS)
LOCAL_PACKAGE_NAME := HinokiRadioBridge
LOCAL_SRC_FILES := $(call all-java-files-under, src)
LOCAL_MANIFEST_FILE := AndroidManifest.xml
LOCAL_JAVA_LIBRARIES := hinoki-mtk-radio-stubs telephony-common
LOCAL_PRIVATE_PLATFORM_APIS := true
LOCAL_CERTIFICATE := platform
LOCAL_PRIVILEGED_MODULE := true
LOCAL_REQUIRED_MODULES := mediatek-telephony-common mediatek-telephony-common.xml
include $(BUILD_PACKAGE)

include $(CLEAR_VARS)
LOCAL_MODULE := mediatek-telephony-common.xml
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT_ETC)/permissions
LOCAL_SRC_FILES := permissions/mediatek-telephony-common.xml
include $(BUILD_PREBUILT)

endif
