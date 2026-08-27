LOCAL_PATH := $(call my-dir)

# Program Binary Service Shim
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    program_binary/program_binary.cpp

LOCAL_SHARED_LIBRARIES := \
    libcutils

LOCAL_MODULE := libshim_program_binary

LOCAL_CFLAGS := -O3 -Wno-unused-variable -Wno-unused-parameter
LOCAL_PROPRIETARY_MODULE := true
include $(BUILD_SHARED_LIBRARY)

# Android 8 generated radio HIDL helpers used by the stock ATCI client.
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    atcid_radio/atcid_radio.cpp

LOCAL_SHARED_LIBRARIES := \
    libc++

LOCAL_MODULE := libshim_atcid_radio
LOCAL_MULTILIB := 64
LOCAL_CFLAGS := -O3
include $(BUILD_SHARED_LIBRARY)

# Android 10 aborts when the Oreo GNSS daemon destroys an already-destroyed
# mutex while tearing down its worker threads.  Scope the compatibility rule
# to mnld via LD_PRELOAD instead of weakening bionic globally.
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    mnld_mutex/mnld_mutex.cpp

LOCAL_SHARED_LIBRARIES := \
    libdl

LOCAL_MODULE := libshim_mnld_mutex
LOCAL_MULTILIB := 32
LOCAL_CFLAGS := -O3 -Wno-cast-align
LOCAL_PROPRIETARY_MODULE := true
include $(BUILD_SHARED_LIBRARY)

# Android 8 AGPS OpenSSL ABI compatibility.
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    agps_ssl/agps_ssl.cpp

LOCAL_SHARED_LIBRARIES := \
    libssl

LOCAL_MODULE := libshim_agps_ssl
LOCAL_MULTILIB := 32
LOCAL_CFLAGS := -O3
LOCAL_PROPRIETARY_MODULE := true
include $(BUILD_SHARED_LIBRARY)

# Android 8 libbase ABI compatibility for the proprietary sensor HAL.
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    sensor_log_message/sensor_log_message.cpp

LOCAL_SHARED_LIBRARIES := \
    libbase

LOCAL_MODULE := libshim_sensor_log_message

LOCAL_CFLAGS := -O3 -Wno-unused-parameter
LOCAL_PROPRIETARY_MODULE := true
include $(BUILD_SHARED_LIBRARY)

# AAL Service Shim
include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    fake_log_print/fake_log_print.cpp

LOCAL_SHARED_LIBRARIES := \
    liblog

LOCAL_MODULE := libshim_fake_log_print

LOCAL_CFLAGS := -O3 -Wno-unused-variable -Wno-unused-parameter
LOCAL_PROPRIETARY_MODULE := true
include $(BUILD_SHARED_LIBRARY)
