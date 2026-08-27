LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := hinoki-radio-state-test
LOCAL_SRC_FILES := radio_state_test.cpp
LOCAL_SHARED_LIBRARIES := \
    android.hardware.radio@1.0 \
    libhidlbase \
    liblog \
    libutils
LOCAL_CFLAGS := -Wall -Werror
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)
LOCAL_MODULE := hinoki-atcid-runner
LOCAL_SRC_FILES := atcid_runner.c
LOCAL_CFLAGS := -Wall -Werror
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)
