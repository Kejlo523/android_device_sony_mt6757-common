/*
 * SPDX-License-Identifier: Apache-2.0
 * Adapter between Android's OMX plugin API and Sony's MTK Oreo OMX core.
 */

#define LOG_TAG "MtkOMXPlugin"

#include <dlfcn.h>
#include <log/log.h>
#include <media/hardware/OMXPluginBase.h>
#include <string.h>

namespace android {

class MtkOMXPlugin final : public OMXPluginBase {
public:
    MtkOMXPlugin()
        : mHandle(dlopen("libMtkOmxCore.so", RTLD_NOW | RTLD_LOCAL)) {
        if (mHandle == nullptr) {
            ALOGE("cannot load libMtkOmxCore.so: %s", dlerror());
            return;
        }
        mInit = load<Init>("Mtk_OMX_Init");
        mDeinit = load<Deinit>("Mtk_OMX_Deinit");
        mEnum = load<ComponentNameEnum>("Mtk_OMX_ComponentNameEnum");
        mGetHandle = load<GetHandle>("Mtk_OMX_GetHandle");
        mFreeHandle = load<FreeHandle>("Mtk_OMX_FreeHandle");
        mGetRoles = load<GetRoles>("Mtk_OMX_GetRolesOfComponent");
        if (!mInit || !mDeinit || !mEnum || !mGetHandle || !mFreeHandle || !mGetRoles ||
                mInit() != OMX_ErrorNone) {
            ALOGE("incomplete or unusable MTK OMX core");
            dlclose(mHandle);
            mHandle = nullptr;
        }
    }

    ~MtkOMXPlugin() override {
        if (mHandle != nullptr) {
            mDeinit();
            dlclose(mHandle);
        }
    }

    OMX_ERRORTYPE makeComponentInstance(const char* name,
            const OMX_CALLBACKTYPE* callbacks, OMX_PTR appData,
            OMX_COMPONENTTYPE** component) override {
        if (!mHandle) return OMX_ErrorUndefined;
        if (isBrokenComponent(name)) {
            ALOGW("rejecting unusable component %s", name);
            return OMX_ErrorComponentNotFound;
        }
        return mGetHandle(reinterpret_cast<OMX_HANDLETYPE*>(component),
                const_cast<char*>(name), appData,
                const_cast<OMX_CALLBACKTYPE*>(callbacks));
    }

    OMX_ERRORTYPE destroyComponentInstance(OMX_COMPONENTTYPE* component) override {
        return mHandle ? mFreeHandle(reinterpret_cast<OMX_HANDLETYPE*>(component))
                       : OMX_ErrorUndefined;
    }

    OMX_ERRORTYPE enumerateComponents(OMX_STRING name, size_t size,
            OMX_U32 index) override {
        if (!mHandle) return OMX_ErrorUndefined;

        // OMXMaster indexes the list exposed by this plugin.  Translate that
        // index while omitting Oreo components that cannot work with the
        // Android 10 kernel/userspace interface.
        OMX_U32 visible = 0;
        for (OMX_U32 raw = 0;; ++raw) {
            OMX_ERRORTYPE err = mEnum(name, static_cast<OMX_U32>(size), raw);
            if (err != OMX_ErrorNone) return err;
            if (isBrokenComponent(name)) continue;
            if (visible++ == index) return OMX_ErrorNone;
        }
    }

    OMX_ERRORTYPE getRolesOfComponent(const char* name,
            Vector<String8>* roles) override {
        roles->clear();
        if (!mHandle) return OMX_ErrorUndefined;
        OMX_U32 count = 0;
        OMX_ERRORTYPE err = mGetRoles(const_cast<char*>(name), &count, nullptr);
        if (err != OMX_ErrorNone || count == 0) return err;
        OMX_U8** values = new OMX_U8*[count];
        for (OMX_U32 i = 0; i < count; ++i) values[i] = new OMX_U8[OMX_MAX_STRINGNAME_SIZE];
        OMX_U32 returned = count;
        err = mGetRoles(const_cast<char*>(name), &returned, values);
        if (err == OMX_ErrorNone) {
            for (OMX_U32 i = 0; i < returned; ++i) roles->push(String8(reinterpret_cast<char*>(values[i])));
        }
        for (OMX_U32 i = 0; i < count; ++i) delete[] values[i];
        delete[] values;
        return err;
    }

private:
    static bool isBrokenComponent(const char* name) {
        return name != nullptr &&
                (!strcmp(name, "OMX.MTK.VIDEO.ENCODER.AVC") ||
                 // All MTK Oreo video decoders use the incompatible Vcodec
                 // userspace ABI. Some loop on open(), while others crash the
                 // Android 10 OMX service after opening the driver.
                 !strncmp(name, "OMX.MTK.VIDEO.DECODER.",
                          strlen("OMX.MTK.VIDEO.DECODER.")));
    }

    template <typename T> T load(const char* symbol) {
        T fn = reinterpret_cast<T>(dlsym(mHandle, symbol));
        if (!fn) ALOGE("missing %s", symbol);
        return fn;
    }
    using Init = OMX_ERRORTYPE (*)();
    using Deinit = OMX_ERRORTYPE (*)();
    using ComponentNameEnum = OMX_ERRORTYPE (*)(OMX_STRING, OMX_U32, OMX_U32);
    using GetHandle = OMX_ERRORTYPE (*)(OMX_HANDLETYPE*, OMX_STRING, OMX_PTR, OMX_CALLBACKTYPE*);
    using FreeHandle = OMX_ERRORTYPE (*)(OMX_HANDLETYPE*);
    using GetRoles = OMX_ERRORTYPE (*)(OMX_STRING, OMX_U32*, OMX_U8**);
    void* mHandle = nullptr;
    Init mInit = nullptr;
    Deinit mDeinit = nullptr;
    ComponentNameEnum mEnum = nullptr;
    GetHandle mGetHandle = nullptr;
    FreeHandle mFreeHandle = nullptr;
    GetRoles mGetRoles = nullptr;
};

extern "C" OMXPluginBase* createOMXPlugin() {
    return new MtkOMXPlugin;
}

}  // namespace android
