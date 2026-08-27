/*
 * Android 10 generates these radio@1.0 helpers inline.  Sony's Oreo MTK
 * radio@1.1 library still imports the old out-of-line symbols, even though
 * atcid never needs their formatting output.  Keep the ABI loadable without
 * replacing the Android 10 radio library used by the framework.
 */

#include <string>

std::string clirToString(int value)
        __asm__("_ZN7android8hardware5radio4V1_08toStringENS2_4ClirE");
std::string operatorInfoToString(const void*)
        __asm__("_ZN7android8hardware5radio4V1_08toStringERKNS2_12OperatorInfoE");
std::string dataProfileToString(const void*)
        __asm__("_ZN7android8hardware5radio4V1_08toStringERKNS2_15DataProfileInfoE");
std::string setupDataCallToString(const void*)
        __asm__("_ZN7android8hardware5radio4V1_08toStringERKNS2_19SetupDataCallResultE");
bool operatorInfoNotEqual(const void*, const void*)
        __asm__("_ZN7android8hardware5radio4V1_0neERKNS2_12OperatorInfoES5_");
bool dataProfileNotEqual(const void*, const void*)
        __asm__("_ZN7android8hardware5radio4V1_0neERKNS2_15DataProfileInfoES5_");
bool setupDataCallNotEqual(const void*, const void*)
        __asm__("_ZN7android8hardware5radio4V1_0neERKNS2_19SetupDataCallResultES5_");

std::string clirToString(int value) {
    return std::to_string(value);
}

std::string operatorInfoToString(const void*) {
    return "OperatorInfo";
}

std::string dataProfileToString(const void*) {
    return "DataProfileInfo";
}

std::string setupDataCallToString(const void*) {
    return "SetupDataCallResult";
}

bool operatorInfoNotEqual(const void* lhs, const void* rhs) {
    return lhs != rhs;
}

bool dataProfileNotEqual(const void* lhs, const void* rhs) {
    return lhs != rhs;
}

bool setupDataCallNotEqual(const void* lhs, const void* rhs) {
    return lhs != rhs;
}
