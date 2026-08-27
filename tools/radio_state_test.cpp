#include <android/hardware/radio/1.0/IRadio.h>
#include <android/hardware/radio/1.0/types.h>
#include <cstdio>
#include <cstdlib>

using android::hardware::radio::V1_0::DeviceStateType;
using android::hardware::radio::V1_0::IRadio;

int main(int argc, char** argv) {
    if (argc != 2 || (argv[1][0] != '0' && argv[1][0] != '1')) {
        std::fprintf(stderr, "usage: %s 0|1\n", argv[0]);
        return EXIT_FAILURE;
    }

    const bool lowDataExpected = argv[1][0] == '1';
    auto radio = IRadio::getService("slot1");
    if (radio == nullptr) {
        std::fprintf(stderr, "android.hardware.radio@1.0/slot1 unavailable\n");
        return EXIT_FAILURE;
    }

    auto result = radio->sendDeviceState(
            0x48494e4f, DeviceStateType::LOW_DATA_EXPECTED, lowDataExpected);
    if (!result.isOk()) {
        std::fprintf(stderr, "HIDL transaction failed: %s\n",
                     result.description().c_str());
        return EXIT_FAILURE;
    }

    std::printf("LOW_DATA_EXPECTED=%d sent\n", lowDataExpected ? 1 : 0);
    return EXIT_SUCCESS;
}
