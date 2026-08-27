/*
 * Sony's Android 8 sensor HAL uses the old libbase LogMessage constructor:
 *
 *   LogMessage(file, line, id, severity, error)
 *
 * Android 10 added a tag argument before error.  Keep the proprietary ABI
 * intact and forward the old entry point to the current constructor.
 */

#include <string>

extern "C" void log_message_ctor_android10(
        void* self, const char* file, unsigned int line, int log_id,
        int severity, const char* tag, int error)
        __asm__("_ZN7android4base10LogMessageC1EPKcjNS0_5LogIdENS0_11LogSeverityES3_i");

extern "C" void log_message_ctor_android8(
        void* self, const char* file, unsigned int line, int log_id,
        int severity, int error)
        __asm__("_ZN7android4base10LogMessageC1EPKcjNS0_5LogIdENS0_11LogSeverityEi");

extern "C" void log_message_ctor_android8(
        void* self, const char* file, unsigned int line, int log_id,
        int severity, int error) {
    log_message_ctor_android10(self, file, line, log_id, severity, nullptr, error);
}

/*
 * The Oreo MTK audio extension expects the out-of-line HIDL-generated
 * audio::V2_0::toString(Result).  Newer generated headers make it inline,
 * so the symbol disappeared even though its ABI did not change.
 */
std::string audio_v2_result_to_string(int result)
        __asm__("_ZN7android8hardware5audio4V2_08toStringENS2_6ResultE");

std::string audio_v2_result_to_string(int result) {
    switch (result) {
        case 0: return "OK";
        case 1: return "NOT_INITIALIZED";
        case 2: return "INVALID_ARGUMENTS";
        case 3: return "INVALID_STATE";
        case 4: return "NOT_SUPPORTED";
        default: return std::to_string(result);
    }
}
