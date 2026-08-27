#include <ui/GraphicBufferMapper.h>
#include <ui/GraphicBuffer.h>
#include <ui/Fence.h>

#include <unistd.h>

// Oreo MTK camera blobs use the pre-P lock() signature. Forward it to the
// Android 10 mapper and leave the optional layout outputs unused.
extern "C" android::status_t legacyGraphicBufferMapperLock(
        android::GraphicBufferMapper* mapper, buffer_handle_t handle,
        uint32_t usage, const android::Rect& bounds, void** vaddr)
        __asm__("_ZN7android19GraphicBufferMapper4lockEPK13native_handlejRKNS_4RectEPPv");

extern "C" android::status_t legacyGraphicBufferMapperLock(
        android::GraphicBufferMapper* mapper, buffer_handle_t handle,
        uint32_t usage, const android::Rect& bounds, void** vaddr) {
    return mapper->lock(handle, usage, bounds, vaddr, nullptr, nullptr);
}

extern "C" android::status_t legacyGraphicBufferLock(
        android::GraphicBuffer* buffer, uint32_t usage, void** vaddr)
        __asm__("_ZN7android13GraphicBuffer4lockEjPPv");

extern "C" android::status_t legacyGraphicBufferLock(
        android::GraphicBuffer* buffer, uint32_t usage, void** vaddr) {
    return buffer->lock(usage, vaddr, nullptr, nullptr);
}

// Oreo exported Fence's destructor from libui. It became inline in newer
// Android releases, so old MTK video blobs still need the legacy symbol.
extern "C" void legacyFenceDestructor(android::Fence* fence)
        __asm__("_ZN7android5FenceD1Ev");

extern "C" void legacyFenceDestructor(android::Fence* fence) {
    const int fd = fence->get();
    if (fd >= 0) close(fd);
}
