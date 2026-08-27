#!/usr/bin/env python3
"""Disable two unsafe legacy AGPS data callbacks in the 64-bit MT6757 GPS HAL.

Sony's Oreo gps.mt6757.so assumes that the legacy AGPS callback table was
registered.  Android 10's MTK HIDL wrapper does not expose IAGnss, leaving the
table null.  The modem then asks for or releases a SUPL data connection and the
HAL dereferences that null table.  Returning from those two void helpers keeps
standalone GNSS and the separate mtk_agpsd path intact.
"""

import pathlib
import sys


PATCHES = {
    0x87CC: bytes.fromhex("ff0303d1"),  # request_data_conn: sub sp, sp, #0xc0
    0x8B20: bytes.fromhex("ff0303d1"),  # release_data_conn: sub sp, sp, #0xc0
}
RET = bytes.fromhex("c0035fd6")


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} gps.mt6757.so", file=sys.stderr)
        return 2

    path = pathlib.Path(sys.argv[1])
    image = bytearray(path.read_bytes())

    for offset, expected in PATCHES.items():
        current = bytes(image[offset:offset + 4])
        if current == RET:
            continue
        if current != expected:
            print(
                f"unexpected bytes at 0x{offset:x}: {current.hex()} "
                f"(expected {expected.hex()})",
                file=sys.stderr,
            )
            return 1
        image[offset:offset + 4] = RET

    path.write_bytes(image)
    print("guarded request_data_conn and release_data_conn")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
