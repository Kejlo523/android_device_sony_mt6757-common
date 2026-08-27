LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libstagefrighthw
LOCAL_VENDOR_MODULE := true
LOCAL_MULTILIB := both
LOCAL_SRC_FILES := MtkOMXPlugin.cpp
LOCAL_HEADER_LIBRARIES := media_plugin_headers
LOCAL_SHARED_LIBRARIES := libdl liblog libutils
include $(BUILD_SHARED_LIBRARY)
