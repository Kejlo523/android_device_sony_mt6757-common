#
# Copyright 2020 The LineageOS Project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

COMMON_PATH := device/sony/mt6757-common

$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)

# Inherit from the common Open Source product configuration
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Vendor
$(call inherit-product-if-exists, vendor/sony/mt6757-common/mt6757-common-vendor.mk)

# Sony's Oreo MTK radio HAL needs the VNDK 27 radio ABI.  Keep it under a
# private SONAME so the Android 10 framework continues using its native copy.
PRODUCT_COPY_FILES += \
    prebuilts/vndk/v27/arm/arch-arm-armv7-a-neon/shared/vndk-core/android.hardware.radio@1.0.so:$(TARGET_COPY_OUT_VENDOR)/lib/android.hardware.radi0@1.0.so \
    prebuilts/vndk/v27/arm64/arch-arm64-armv8-a/shared/vndk-core/android.hardware.radio@1.0.so:$(TARGET_COPY_OUT_VENDOR)/lib64/android.hardware.radi0@1.0.so \
    $(COMMON_PATH)/ril-compat/libbind3r.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libbind3r.so \
    $(COMMON_PATH)/ril-compat/libutilz.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libutilz.so \
    prebuilts/vndk/v27/arm64/arch-arm64-armv8-a/shared/vndk-sp/libcutils.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libcutilz.so \
    prebuilts/vndk/v27/arm64/arch-arm64-armv8-a/shared/vndk-sp/libbase.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libbas3.so

# The XA1 boots the system partition directly as a read-only root. Keep these
# directories in system.img so fs_mgr can mount the device-specific partitions.
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/rootdir/mountpoint.marker:root/nvdata/.mountpoint \
    $(COMMON_PATH)/rootdir/mountpoint.marker:root/nvcfg/.mountpoint \
    $(COMMON_PATH)/rootdir/mountpoint.marker:root/persist/.mountpoint \
    $(COMMON_PATH)/rootdir/mountpoint.marker:root/protect_f/.mountpoint \
    $(COMMON_PATH)/rootdir/mountpoint.marker:root/protect_s/.mountpoint \
    $(COMMON_PATH)/rootdir/mountpoint.marker:root/custom/.mountpoint

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(COMMON_PATH)/overlay \
    $(COMMON_PATH)/overlay-lineage

# Screen Density
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxhdpi

# Audio
PRODUCT_PACKAGES += \
    libsensorndkbridge \
    android.hardware.audio@2.0-impl \
    android.hardware.audio@2.0-service \
    android.hardware.audio.effect@2.0-impl \
    android.hardware.audio.effect@2.0-service \
    audio.r_submix.default \
    audio.a2dp.default \
    audio.usb.default \
    audio_policy.stub \
    libaudio-resampler \
    libtinyalsa \
    libtinycompress \
    libtinymix \
    libtinyxml \
    libtinyxml2 \
    libxml2

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/audio/audio_effects.xml:system/etc/audio_effects.xml \
    $(COMMON_PATH)/configs/audio/AudioParamOptions.xml:system/vendor/etc/audio_param/AudioParamOptions.xml \
    $(COMMON_PATH)/configs/audio/a2dp_audio_policy_configuration.xml:system/vendor/etc/a2dp_audio_policy_configuration.xml \
    $(COMMON_PATH)/configs/audio/audio_device.xml:system/vendor/etc/audio_device.xml \
    $(COMMON_PATH)/configs/audio/audio_em.xml:system/vendor/etc/audio_em.xml \
    $(COMMON_PATH)/configs/audio/audio_policy.conf:system/vendor/etc/audio_policy.conf \
    $(COMMON_PATH)/configs/audio/audio_policy_configuration.xml:system/vendor/etc/audio_policy_configuration.xml \
    $(COMMON_PATH)/configs/audio/audio_policy_configuration.xml:system/odm/etc/audio_policy_configuration.xml \
    $(COMMON_PATH)/configs/audio/audio_policy_volumes.xml:system/vendor/etc/audio_policy_volumes.xml \
    $(COMMON_PATH)/configs/audio/default_volume_tables.xml:system/vendor/etc/default_volume_tables.xml \
    $(COMMON_PATH)/configs/audio/r_submix_audio_policy_configuration.xml:system/vendor/etc/r_submix_audio_policy_configuration.xml \
    $(COMMON_PATH)/configs/audio/usb_audio_policy_configuration.xml:system/vendor/etc/usb_audio_policy_configuration.xml

# Bluetooth
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.0-impl \
    android.hardware.bluetooth@1.0-service

# Camera
PRODUCT_PACKAGES += \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service \
    android.hardware.camera.device@3.2-impl \
    android.hardware.camera.device@3.2-service \
    libcamera_legacy_ui_shim \
    Snap

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/camera-compat/libhidltransp0rt.so:$(TARGET_COPY_OUT_VENDOR)/lib/libhidltransp0rt.so \
    $(COMMON_PATH)/camera-compat/libbaze.so:$(TARGET_COPY_OUT_VENDOR)/lib/libbaze.so \
    $(COMMON_PATH)/camera-compat/android.hardware.sensorz@1.0.so:$(TARGET_COPY_OUT_VENDOR)/lib/android.hardware.sensorz@1.0.so \
    $(COMMON_PATH)/camera-compat/android.hardware.camera.devic3@3.2.so:$(TARGET_COPY_OUT_VENDOR)/lib/android.hardware.camera.devic3@3.2.so

# The legacy MTK media stack is not compatible with Android 10 Codec2. Apart
# from breaking audio playback, a stuck Codec2 Vorbis decoder prevents
# SoundPool from shutting down and freezes every app switching camera modes.
PRODUCT_PROPERTY_OVERRIDES += \
    debug.stagefright.ccodec=0

# Configstore
PRODUCT_PACKAGES += \
    android.hardware.configstore@1.0-impl \
    android.hardware.configstore@1.0-service

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service

# Gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-impl \
    android.hardware.gatekeeper@1.0-service 

# GPS
PRODUCT_PACKAGES += \
    libcurl

# Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.mapper@2.0-impl \
    libGLES_android \
    libion

# HIDL
PRODUCT_PACKAGES += \
    android.hidl.base@1.0 \
    android.hidl.manager@1.0

# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-impl \
    android.hardware.keymaster@3.0-service

# Keylayout
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/keylayout/mtk-kpd.kl:system/usr/keylayout/mtk-kpd.kl \
    $(COMMON_PATH)/configs/keylayout/mtk-tpd.idc:system/usr/idc/mtk-tpd.idc

# Media
PRODUCT_COPY_FILES += \
    prebuilts/vndk/v27/arm64/arch-arm-armv7-a-neon/shared/vndk-core/libui.so:$(TARGET_COPY_OUT_VENDOR)/lib/libu8.so \
    prebuilts/vndk/v27/arm64/arch-arm64-armv8-a/shared/vndk-core/libui.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libu8.so \
    vendor/sony/mt6757-common/proprietary/vendor/lib/libaudiocompensationfilter.so:system/lib/libaudiocompensationfilter.so \
    vendor/sony/mt6757-common/proprietary/vendor/lib/libaudiocompensationfilterc.so:system/lib/libaudiocompensationfilterc.so \
    vendor/sony/mt6757-common/proprietary/vendor/lib/libaudiocomponentengine.so:system/lib/libaudiocomponentengine.so \
    vendor/sony/mt6757-common/proprietary/vendor/lib/libaudiocomponentenginec.so:system/lib/libaudiocomponentenginec.so \
    $(COMMON_PATH)/configs/media/media_codecs.xml:system/vendor/etc/media_codecs.xml \
    $(COMMON_PATH)/configs/media/media_codecs_google_audio.xml:system/vendor/etc/media_codecs_google_audio.xml \
    $(COMMON_PATH)/configs/media/media_codecs_google_video_le.xml:system/vendor/etc/media_codecs_google_video_le.xml \
    $(COMMON_PATH)/configs/media/media_codecs_mediatek_audio.xml:system/vendor/etc/media_codecs_mediatek_audio.xml \
    $(COMMON_PATH)/configs/media/media_codecs_mediatek_video.xml:system/vendor/etc/media_codecs_mediatek_video.xml \
    $(COMMON_PATH)/configs/media/media_codecs_performance.xml:system/vendor/etc/media_codecs_performance.xml \
    $(COMMON_PATH)/configs/media/media_profiles.xml:system/vendor/etc/media_profiles.xml \
    $(COMMON_PATH)/configs/media/media_profiles_V1_0.xml:system/vendor/etc/media_profiles_V1_0.xml

# Memtrack
PRODUCT_PACKAGES += \
    android.hardware.memtrack@1.0-impl \
    android.hardware.memtrack@1.0-service

# Misc
PRODUCT_PACKAGES += \
    librs_jni \
    libnl_2

# MTKRC
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.mtkrc.path=/vendor/etc/init/hw/ \
    ro.adb.secure=0

# Net
PRODUCT_PACKAGES += \
    netutils-wrapper-1.0

# Use one NFC HAL owner only. The AOSP HIDL wrapper works with Sony's legacy
# nfc_nci module; the parallel NXP extension races it for the controller.
PRODUCT_PACKAGES += \
    android.hardware.nfc@1.0 \
    android.hardware.nfc@1.0-impl \
    android.hardware.nfc@1.0-service \
    com.android.nfc_extras \
    NfcNci \
    Tag

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
    $(COMMON_PATH)/configs/nfc/libnfc-nci.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nci.conf

# OMX
PRODUCT_PACKAGES += \
    android.hardware.media.omx@1.0-service \
    libstagefrighthw

# Shim Libraries
PRODUCT_PACKAGES += \
    libandroid_net \
    libshim_agps_ssl \
    libshim_atcid_radio \
    libshim_mnld_mutex \
    libshim_program_binary \
    libshim_fake_log_print \
    libshim_sensor_log_message

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:system/vendor/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:system/vendor/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/vendor/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/vendor/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.faketouch.xml:system/vendor/etc/permissions/android.hardware.faketouch.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/vendor/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:system/vendor/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/vendor/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:system/vendor/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/vendor/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/vendor/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/vendor/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:system/vendor/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:system/vendor/etc/permissions/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/vendor/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:system/vendor/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/vendor/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.xml:system/vendor/etc/permissions/android.hardware.touchscreen.multitouch.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.xml:system/vendor/etc/permissions/android.hardware.touchscreen.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/vendor/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/vendor/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.vr.high_performance.xml:system/vendor/etc/permissions/android.hardware.vr.high_performance.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:system/vendor/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_0_3.xml:system/vendor/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/vendor/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/vendor/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.midi.xml:system/vendor/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/vendor/etc/permissions/android.software.sip.voip.xml \
    frameworks/native/data/etc/android.software.vr.xml:system/vendor/etc/permissions/android.software.vr.xml \
    frameworks/native/data/etc/android.software.webview.xml:system/vendor/etc/permissions/android.software.webview.xml \
    frameworks/native/data/etc/handheld_core_hardware.xml:system/vendor/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:system/vendor/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:system/vendor/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/com.android.nfc_extras.xml:system/vendor/etc/permissions/com.android.nfc_extras.xml

# Power
PRODUCT_PACKAGES += \
    android.hardware.power@1.0

# Radio
PRODUCT_PACKAGES += \
    android.hardware.broadcastradio@1.0-impl \
    android.hardware.broadcastradio@1.0-service

# Renderscript
PRODUCT_PACKAGES += \
    android.hardware.renderscript@1.0-impl

# RIL
PRODUCT_PACKAGES += \
    android.hardware.radio@1.0 \
    android.hardware.radio.deprecated@1.0

# Register the MTK-only radio callback channel used for incoming call
# pre-alerts (RIL_UNSOL_INCOMING_CALL_INDICATION / +EAIC).
PRODUCT_PACKAGES += \
    HinokiRadioBridge \
    mediatek-telephony-common.xml

# Android 10 no longer accepts these Oreo-era dex-only prebuilts on the
# platform boot class path. Keep them installed while the framework shims
# are ported to proper Soong java_import modules.
PRODUCT_PACKAGES += \
    ModemSwitcher \
    com.sonyericsson.idd_impl \
    com.sonymobile.miscta_impl \
    mediatek-common \
    mediatek-framework \
    mediatek-ims-common \
    mediatek-packages-teleservice \
    mediatek-telecom-common \
    mediatek-telephony-base \
    mediatek-telephony-common \
    somc-ext-telephony

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/ril/apns-conf.xml:system/etc/apns-conf.xml \
    $(COMMON_PATH)/configs/permissions/com.compal.modemswitcher.xml:system/etc/permissions/com.compal.modemswitcher.xml \
    $(COMMON_PATH)/configs/permissions/com.sonyericsson.idd.xml:system/etc/permissions/com.sonyericsson.idd.xml \
    $(COMMON_PATH)/configs/permissions/com.sonymobile.miscta.xml:system/etc/permissions/com.sonymobile.miscta.xml \
    $(COMMON_PATH)/configs/permissions/com.sonymobile.telephony.extension.somc-ext-telephony.xml:system/etc/permissions/com.sonymobile.telephony.extension.somc-ext-telephony.xml \
    $(COMMON_PATH)/configs/permissions/mediatek-packages-teleservice.xml:system/etc/permissions/mediatek-packages-teleservice.xml \
    $(COMMON_PATH)/configs/permissions/privapp-permissions-mediatek.xml:system/etc/permissions/privapp-permissions-mediatek.xml

# Rootdir
PRODUCT_PACKAGES += \
    fstab.enableswap \
    fstab.mt6757 \
    fstab.mt6757.root \
    init.connectivity.rc \
    init.modem.rc \
    init.mt6757.rc \
    init.mt6757.usb.rc \
    init.project.rc \
    init.recovery.mt6757.rc \
    init.sensor_1_0.rc \
    init.sony-bootstrap-checkfirstboot.rc \
    init.sony-bootstrap-mr.rc \
    init.sony-bootstrap.rc \
    init.sony-bootstrap-wipedata.rc \
    init.sony-drm.rc \
    init.sony-enterprise.rc \
    init.sony-fota.rc \
    init.sony-trimarea.rc \
    ueventd.mt6757.rc

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/rootdir/sbin/checkfirstboot:root/sbin/checkfirstboot \
    $(COMMON_PATH)/rootdir/sbin/fota-ua:root/sbin/fota-ua \
    $(COMMON_PATH)/rootdir/sbin/fuelgauged_static:root/sbin/fuelgauged_static \
    $(COMMON_PATH)/rootdir/sbin/mr:root/sbin/mr \
    $(COMMON_PATH)/rootdir/sbin/tad_static:$(TARGET_COPY_OUT_VENDOR)/bin/tad_static \
    $(COMMON_PATH)/rootdir/sbin/ua-data-mounter:root/sbin/ua-data-mounter \
    $(COMMON_PATH)/rootdir/sbin/wipedata:root/sbin/wipedata

# Seccomp
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/seccomp/mediacodec.policy:system/vendor/etc/seccomp_policy/mediacodec.policy \
    $(COMMON_PATH)/seccomp/mediaextractor.policy:system/vendor/etc/seccomp_policy/mediaextractor.policy

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal@1.0-impl \
    android.hardware.thermal@1.0-service

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/thermal/thermal.conf:system/vendor/etc/.tp/thermal.conf \
    $(COMMON_PATH)/configs/thermal/thermal.off.conf:system/vendor/etc/.tp/thermal.off.conf \
    $(COMMON_PATH)/configs/thermal/.ht120.mtc:system/vendor/etc/.tp/.ht120.mtc \
    $(COMMON_PATH)/configs/thermal/.thermal_meta.conf:system/vendor/etc/.tp/.thermal_meta.conf \
    $(COMMON_PATH)/configs/thermal/.thermal_policy_00:system/vendor/etc/.tp/.thermal_policy_00 \
    $(COMMON_PATH)/configs/thermal/.thermal_policy_01:system/vendor/etc/.tp/.thermal_policy_01 \
    $(COMMON_PATH)/configs/thermal/.thermal_policy_02:system/vendor/etc/.tp/.thermal_policy_02 \
    $(COMMON_PATH)/configs/thermal/.thermal_policy_05:system/vendor/etc/.tp/.thermal_policy_05 \
    $(COMMON_PATH)/configs/thermal/.thermal_policy_06:system/vendor/etc/.tp/.thermal_policy_06

# USB
PRODUCT_PACKAGES += \
    android.hardware.usb@1.0 \
    android.hardware.usb@1.0-service.basic \
    android.hardware.usb.gadget@1.0-impl \
    android.hardware.usb.gadget@1.0-service

# Vibrator
PRODUCT_PACKAGES += \
    android.hardware.vibrator@1.0-impl \
    android.hardware.vibrator@1.0-service

# VNDK-SP
PRODUCT_PACKAGES += \
    vndk-sp

# WiFi
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0 \
    android.hardware.wifi@1.0-service \
    lib_driver_cmd_mt66xx \
    libwifi-hal-mt66xx \
    libwpa_client \
    hostapd \
    hostapd_cli \
    wpa_supplicant

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/wifi/p2p_supplicant_overlay.conf:system/vendor/etc/wifi/p2p_supplicant_overlay.conf \
    $(COMMON_PATH)/configs/wifi/wpa_supplicant.conf:system/vendor/etc/wifi/wpa_supplicant.conf \
    $(COMMON_PATH)/configs/wifi/wpa_supplicant_overlay.conf:system/vendor/etc/wifi/wpa_supplicant_overlay.conf

# Dalvik Tweak
PRODUCT_TAGS += dalvik.gc.type-precise

# Dalvik heap configuration
#
# The old device tree referenced phone-xxxhdpi-3072-dalvik-heap.mk, which does
# not exist on Android 10.  inherit-product-if-exists therefore silently left
# ART at its 16 MiB fallback growth limit.  Repository parsing in F-Droid and
# modern WebView applications then died with OutOfMemoryError.  Hinoki has a
# 320 dpi display and 3 GiB RAM; this AOSP profile provides a 192 MiB growth
# limit and a 512 MiB maximum heap.
$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)
