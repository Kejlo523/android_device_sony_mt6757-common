/*
 * Sony's Oreo mtk_agpsd asks BoringSSL for the obsolete SSLv3 method.
 * Android 10 deliberately removed that entry point, but still exposes the
 * protocol-negotiating TLS client method with the same ABI.  SUPL uses the
 * client side only; keep the server alias as a defensive compatibility shim.
 */

#include <dlfcn.h>
#include <openssl/ssl.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

namespace {

// Oreo exposed callback/cb_arg in BIO.  They were removed before Android Q,
// shifting init and ptr by eight bytes in this 32-bit blob.  MTK's custom BIO
// callbacks access these fields directly.  Give those callbacks an Oreo view
// while BoringSSL and ordinary BIO_s_mem users retain their native ABI.
struct OreoBio {
    const BIO_METHOD* method;
    void* callback;
    char* cb_arg;
    int init;
    int shutdown;
    int flags;
    int retry_reason;
    int num;
    unsigned int references;
    void* ptr;
    BIO* next_bio;
    size_t num_read;
    size_t num_write;
};
static_assert(sizeof(void*) == 4, "Only the 32-bit Oreo AGPS blob needs this bridge");
static_assert(offsetof(OreoBio, init) == 12, "Oreo BIO init ABI");
static_assert(offsetof(OreoBio, ptr) == 36, "Oreo BIO private-data ABI");

const BIO_METHOD kOreoMarker = {};
struct BioState {
    OreoBio legacy;
    const BIO_METHOD* original;
};

BioState* stateOf(BIO* bio) {
    return static_cast<BioState*>(BIO_get_data(bio));
}

BIO* legacyView(BioState* state) {
    return reinterpret_cast<BIO*>(&state->legacy);
}

void syncFlags(BIO* bio, BioState* state) {
    BIO_clear_flags(bio, ~0);
    BIO_set_flags(bio, state->legacy.flags);
    BIO_set_init(bio, state->legacy.init);
}

int bridgeWrite(BIO* bio, const char* data, int length) {
    BioState* state = stateOf(bio);
    state->legacy.flags = BIO_test_flags(bio, ~0);
    const int result = state->original->bwrite(legacyView(state), data, length);
    syncFlags(bio, state);
    return result;
}

int bridgeRead(BIO* bio, char* data, int length) {
    BioState* state = stateOf(bio);
    state->legacy.flags = BIO_test_flags(bio, ~0);
    const int result = state->original->bread(legacyView(state), data, length);
    syncFlags(bio, state);
    return result;
}

long bridgeCtrl(BIO* bio, int cmd, long arg, void* ptr) {
    BioState* state = stateOf(bio);
    if (state == nullptr || state->original->ctrl == nullptr) return 0;
    const long result = state->original->ctrl(legacyView(state), cmd, arg, ptr);
    syncFlags(bio, state);
    return result;
}

int bridgeDestroy(BIO* bio) {
    BioState* state = stateOf(bio);
    if (state != nullptr) {
        if (state->original->destroy != nullptr) {
            state->original->destroy(legacyView(state));
        }
        free(state);
        BIO_set_data(bio, nullptr);
    }
    return 1;
}

const BIO_METHOD kBridgeMethod = {
    BIO_TYPE_SOURCE_SINK | 0x80, "MTK Oreo BIO bridge",
    bridgeWrite, bridgeRead, nullptr, nullptr, bridgeCtrl,
    nullptr, bridgeDestroy, nullptr,
};

bool isMtkMethod(const BIO_METHOD* method) {
    Dl_info info = {};
    if (method == nullptr || dladdr(method, &info) == 0 || info.dli_fname == nullptr) {
        return false;
    }
    const char* basename = strrchr(info.dli_fname, '/');
    return strcmp(basename != nullptr ? basename + 1 : info.dli_fname, "mtk_agpsd") == 0;
}

}  // namespace

extern "C" BIO* BIO_new(const BIO_METHOD* method) {
    using NewBio = BIO* (*)(const BIO_METHOD*);
    static NewBio real_new = reinterpret_cast<NewBio>(dlsym(RTLD_NEXT, "BIO_new"));
    if (real_new == nullptr) return nullptr;
    if (!isMtkMethod(method)) return real_new(method);

    // The stock method has only read, write, control, create and destroy.
    // Do not adapt a different callback contract silently.
    if (method->bread == nullptr || method->bwrite == nullptr ||
        method->bputs != nullptr || method->bgets != nullptr ||
        method->callback_ctrl != nullptr) return nullptr;
    BioState* state = static_cast<BioState*>(calloc(1, sizeof(BioState)));
    if (state == nullptr) return nullptr;
    state->original = method;
    state->legacy.method = &kOreoMarker;
    state->legacy.shutdown = 1;
    state->legacy.references = 1;
    if (method->create != nullptr && !method->create(legacyView(state))) {
        free(state);
        return nullptr;
    }
    BIO* bio = real_new(&kBridgeMethod);
    if (bio == nullptr) {
        if (method->destroy != nullptr) method->destroy(legacyView(state));
        free(state);
        return nullptr;
    }
    BIO_set_data(bio, state);
    syncFlags(bio, state);
    return bio;
}

extern "C" void BIO_clear_retry_flags(BIO* bio) {
    if (bio->method == &kOreoMarker) {
        reinterpret_cast<OreoBio*>(bio)->flags &= ~(BIO_FLAGS_RWS | BIO_FLAGS_SHOULD_RETRY);
        return;
    }
    BIO_clear_flags(bio, BIO_FLAGS_RWS | BIO_FLAGS_SHOULD_RETRY);
}

extern "C" void BIO_set_retry_read(BIO* bio) {
    if (bio->method == &kOreoMarker) {
        reinterpret_cast<OreoBio*>(bio)->flags |= BIO_FLAGS_READ | BIO_FLAGS_SHOULD_RETRY;
        return;
    }
    BIO_set_flags(bio, BIO_FLAGS_READ | BIO_FLAGS_SHOULD_RETRY);
}

extern "C" const ssl_method_st* TLS_client_method();
extern "C" const ssl_method_st* TLS_server_method();

extern "C" const ssl_method_st* SSLv3_client_method() {
    return TLS_client_method();
}

extern "C" const ssl_method_st* SSLv3_server_method() {
    return TLS_server_method();
}
