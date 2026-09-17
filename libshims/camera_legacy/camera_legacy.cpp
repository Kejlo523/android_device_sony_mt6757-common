#include <stdint.h>

#include <string>
#include <ui/GraphicBuffer.h>
#include <ui/GraphicBufferMapper.h>
#include <ui/Rect.h>

// Oreo's four-argument overload disappeared in Android 10.  Preserve its ABI
// for the proprietary camera client and delegate to the current implementation.
extern "C" android::status_t legacyGraphicBufferMapperLock(
        android::GraphicBufferMapper* mapper,
        buffer_handle_t handle,
        uint32_t usage,
        const android::Rect* bounds,
        void** vaddr)
        __asm__("_ZN7android19GraphicBufferMapper4lockEPK13native_handlejRKNS_4RectEPPv");

extern "C" android::status_t legacyGraphicBufferMapperLock(
        android::GraphicBufferMapper* mapper,
        buffer_handle_t handle,
        uint32_t usage,
        const android::Rect* bounds,
        void** vaddr) {
    return mapper->lock(handle, usage, *bounds, vaddr, nullptr, nullptr);
}

extern "C" android::status_t legacyGraphicBufferLock(
        android::GraphicBuffer* buffer,
        uint32_t usage,
        void** vaddr)
        __asm__("_ZN7android13GraphicBuffer4lockEjPPv");

extern "C" android::status_t legacyGraphicBufferLock(
        android::GraphicBuffer* buffer,
        uint32_t usage,
        void** vaddr) {
    return buffer->lock(usage, vaddr, nullptr, nullptr);
}

// This generated HIDL helper was exported on Oreo but is inline on Android 10.
// Camera blobs use it only for diagnostics, so a stable numeric representation
// is sufficient while retaining the exact old symbol and C++ return ABI.
std::string legacyPixelFormatToString(int32_t value)
        __asm__("_ZN7android8hardware8graphics6common4V1_08toStringENS3_11PixelFormatE");

std::string legacyPixelFormatToString(int32_t value) {
    return std::to_string(value);
}

std::string legacyBufferUsageToString(uint64_t value)
        __asm__("_ZN7android8hardware8graphics6common4V1_08toStringINS3_11BufferUsageEEENSt3__112basic_stringIcNS6_11char_traitsIcEENS6_9allocatorIcEEEEy");

std::string legacyBufferUsageToString(uint64_t value) {
    return std::to_string(value);
}

std::string legacyDataspaceToString(int32_t value)
        __asm__("_ZN7android8hardware8graphics6common4V1_08toStringINS3_9DataspaceEEENSt3__112basic_stringIcNS6_11char_traitsIcEENS6_9allocatorIcEEEEi");

std::string legacyDataspaceToString(int32_t value) {
    return std::to_string(value);
}
